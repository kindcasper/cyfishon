import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'database_service.dart';
import 'telegram_service.dart';
import 'log_service.dart';

/// Сервис для фоновой синхронизации данных
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  final TelegramService _telegram = TelegramService();
  final LogService _log = LogService();
  final Connectivity _connectivity = Connectivity();

  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;

  /// Запустить фоновую синхронизацию
  Future<void> startSync() async {
    await _log.info('Запуск сервиса синхронизации');
    
    // Проверяем начальное состояние интернета
    await _checkConnectivity();
    
    // Подписываемся на изменения состояния сети
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOnline = _isOnline;
        _isOnline = results.any((result) => 
          result != ConnectivityResult.none && 
          result != ConnectivityResult.bluetooth
        );
        
        if (!wasOnline && _isOnline) {
          await _log.logInternetRestored();
          // Запускаем синхронизацию при восстановлении интернета
          await syncPendingCatches();
        } else if (wasOnline && !_isOnline) {
          await _log.logNoInternet();
        }
      },
    );
    
    // Запускаем периодическую синхронизацию
    _startPeriodicSync();
    
    // Выполняем первую синхронизацию
    await syncPendingCatches();
  }

  /// Остановить синхронизацию
  void stopSync() {
    _log.info('Остановка сервиса синхронизации');
    _syncTimer?.cancel();
    _syncTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Запустить периодическую синхронизацию
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: AppConfig.syncIntervalSeconds),
      (_) async {
        if (_isOnline && !_isSyncing) {
          await syncPendingCatches();
        }
      },
    );
  }

  /// Проверить подключение к интернету
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((result) => 
      result != ConnectivityResult.none && 
      result != ConnectivityResult.bluetooth
    );
  }

  /// Проверить наличие интернета через Telegram API
  Future<bool> hasInternetConnection() async {
    if (!_isOnline) return false;
    
    // Дополнительно проверяем через Telegram API
    return await _telegram.checkConnection();
  }

  /// Синхронизировать все ожидающие поимки
  Future<void> syncPendingCatches() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      await _log.logSyncStart();
      
      // Получаем все неотправленные поимки
      final pendingCatches = await _db.getPendingCatches();
      
      if (pendingCatches.isEmpty) {
        await _log.info('Нет поимок для синхронизации');
        return;
      }
      
      await _log.info(
        'Найдено поимок для синхронизации',
        'Количество: ${pendingCatches.length}',
      );
      
      int synced = 0;
      int failed = 0;
      
      // Отправляем каждую поимку
      for (final catchRecord in pendingCatches) {
        if (catchRecord.id == null) continue;
        
        try {
          // Пытаемся отправить
          final success = await _telegram.sendMessage(catchRecord);
          
          if (success) {
            // Обновляем статус на "отправлено"
            await _db.updateCatchStatus(
              catchRecord.id!,
              AppConfig.statusSent,
            );
            synced++;
          } else {
            // Увеличиваем счетчик попыток
            await _db.incrementRetryCount(catchRecord.id!);
            
            // Обновляем статус на "ошибка"
            await _db.updateCatchStatus(
              catchRecord.id!,
              AppConfig.statusFailed,
              lastError: 'Ошибка отправки в Telegram',
            );
            failed++;
          }
        } catch (e) {
          // Логируем ошибку и продолжаем со следующей поимкой
          await _log.error(
            'Ошибка синхронизации поимки ${catchRecord.id}',
            e,
          );
          
          await _db.updateCatchStatus(
            catchRecord.id!,
            AppConfig.statusFailed,
            lastError: e.toString(),
          );
          failed++;
        }
        
        // Небольшая задержка между отправками
        if (synced + failed < pendingCatches.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      await _log.logSyncComplete(synced, failed);
    } finally {
      _isSyncing = false;
    }
  }

  /// Получить интервал повторных попыток из настроек
  Future<int> getRetryInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConfig.keyRetryInterval) ?? AppConfig.defaultRetryMinutes;
  }

  /// Установить интервал повторных попыток
  Future<void> setRetryInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConfig.keyRetryInterval, minutes);
    
    // Перезапускаем таймер с новым интервалом
    _startPeriodicSync();
    
    await _log.logSettingsChanged('Интервал повторных попыток', '$minutes минут');
  }

  /// Принудительная синхронизация
  Future<void> forceSyncNow() async {
    await _log.info('Принудительная синхронизация');
    await syncPendingCatches();
  }

  /// Получить статус синхронизации
  bool get isSyncing => _isSyncing;

  /// Получить статус подключения
  bool get isOnline => _isOnline;
}
