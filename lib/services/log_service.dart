import '../models/log_entry.dart';
import 'database_service.dart';

/// Сервис для логирования всех действий в приложении
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final DatabaseService _db = DatabaseService();

  /// Логировать информационное сообщение
  Future<void> info(String message, [String? details]) async {
    final log = LogEntry.info(message, details);
    await _db.insertLog(log);
    _printLog(log);
  }

  /// Логировать предупреждение
  Future<void> warning(String message, [String? details]) async {
    final log = LogEntry.warning(message, details);
    await _db.insertLog(log);
    _printLog(log);
  }

  /// Логировать ошибку
  Future<void> error(String message, [dynamic error]) async {
    final log = LogEntry.error(message, error);
    await _db.insertLog(log);
    _printLog(log);
  }

  /// Вывести лог в консоль для отладки
  void _printLog(LogEntry log) {
    print('${log.levelIcon} [${log.formattedTime}] ${log.level}: ${log.message}');
    if (log.details != null) {
      print('   Детали: ${log.details}');
    }
  }

  // ============= Специализированные методы логирования =============

  /// Логировать запуск приложения
  Future<void> logAppStart() async {
    await info('Приложение запущено');
  }

  /// Логировать установку имени пользователя
  Future<void> logUserNameSet(String userName) async {
    await info('Установлено имя пользователя', userName);
  }

  /// Логировать запрос GPS координат
  Future<void> logLocationRequest() async {
    await info('Запрос GPS координат');
  }

  /// Логировать получение координат
  Future<void> logLocationReceived(double lat, double lon, double accuracy) async {
    await info(
      'Координаты получены',
      'Широта: $lat, Долгота: $lon, Точность: ${accuracy}м',
    );
  }

  /// Логировать ошибку получения координат
  Future<void> logLocationError(String error) async {
    await this.error('Ошибка получения координат', error);
  }

  /// Логировать создание новой поимки
  Future<void> logCatchCreated(String catchType, String userName) async {
    await info(
      'Создана новая поимка',
      'Тип: $catchType, Пользователь: $userName',
    );
  }

  /// Логировать попытку отправки в Telegram
  Future<void> logTelegramSendAttempt(int catchId) async {
    await info('Попытка отправки в Telegram', 'ID поимки: $catchId');
  }

  /// Логировать успешную отправку в Telegram
  Future<void> logTelegramSendSuccess(int catchId) async {
    await info('Успешно отправлено в Telegram', 'ID поимки: $catchId');
  }

  /// Логировать ошибку отправки в Telegram
  Future<void> logTelegramSendError(int catchId, String error) async {
    await this.error(
      'Ошибка отправки в Telegram',
      'ID поимки: $catchId, Ошибка: $error',
    );
  }

  /// Логировать запуск синхронизации
  Future<void> logSyncStart() async {
    await info('Запущена синхронизация');
  }

  /// Логировать завершение синхронизации
  Future<void> logSyncComplete(int synced, int failed) async {
    await info(
      'Синхронизация завершена',
      'Отправлено: $synced, Ошибок: $failed',
    );
  }

  /// Логировать изменение настроек
  Future<void> logSettingsChanged(String setting, dynamic value) async {
    await info(
      'Изменена настройка',
      '$setting: $value',
    );
  }

  /// Логировать отсутствие интернета
  Future<void> logNoInternet() async {
    await warning('Отсутствует подключение к интернету');
  }

  /// Логировать восстановление интернета
  Future<void> logInternetRestored() async {
    await info('Подключение к интернету восстановлено');
  }

  /// Логировать очистку старых логов
  Future<void> logCleanup(int deleted) async {
    await info('Очистка старых логов', 'Удалено записей: $deleted');
  }

  // ============= Утилиты =============

  /// Получить логи из базы данных
  Future<List<LogEntry>> getLogs({
    String? level,
    int? limit,
    int? offset,
  }) async {
    return await _db.getLogs(
      level: level,
      limit: limit,
      offset: offset,
    );
  }

  /// Очистить старые логи
  Future<void> clearOldLogs() async {
    await _db.clearOldLogs();
    await info('Старые логи очищены');
  }

  /// Очистить все логи
  Future<void> clearAllLogs() async {
    await _db.clearAllLogs();
    // Не логируем это действие, так как логи уже очищены
  }
}
