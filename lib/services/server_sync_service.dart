import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/catch_record.dart';
import '../config/app_config.dart';
import 'log_service.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Сервис для синхронизации данных с сервером
class ServerSyncService {
  static final ServerSyncService _instance = ServerSyncService._internal();
  factory ServerSyncService() => _instance;
  ServerSyncService._internal();

  final LogService _log = LogService();
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  
  // URL API сервера
  static const String _baseUrl = 'https://fishingcy.com/cyfishon/api.php';
  
  // Таймауты и интервалы (те же что и для Telegram)
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxRetries = 3;

  /// Отправить поимку на сервер
  Future<bool> sendCatchToServer(CatchRecord catch_) async {
    try {
      await _log.info('Отправка поимки на сервер: ${catch_.id}');
      
      // Проверяем интернет соединение
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        await _log.warning('Нет интернет соединения для отправки на сервер');
        return false;
      }

      // Подготавливаем данные для отправки
      final data = {
        'action': 'add_catch',
        'user_name': catch_.userName,
        'catch_type': catch_.catchType,
        'latitude': catch_.latitude,
        'longitude': catch_.longitude,
        'timestamp': catch_.timestamp.toIso8601String().substring(0, 19).replaceAll('T', ' '),
        'telegram_sent': catch_.telegramStatus == AppConfig.statusSent,
        'telegram_sent_at': catch_.telegramStatus == AppConfig.statusSent ? catch_.updatedAt.toIso8601String().substring(0, 19).replaceAll('T', ' ') : null,
        'app_version': AppConfig.version,
        'device_info': await _getDeviceInfo(),
      };

      // Отправляем запрос с повторными попытками
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          await _log.info('Попытка отправки на сервер $attempt/$_maxRetries');
          
          final response = await http.post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'User-Agent': 'CyFishON/${AppConfig.version}',
            },
            body: json.encode(data),
          ).timeout(_requestTimeout);

          if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = json.decode(response.body);
            
            if (responseData['success'] == true) {
              await _log.info('Поимка успешно отправлена на сервер: ${responseData['catch_id']}');
              
              // Обновляем статус отправки в локальной базе
              await _updateServerSentStatus(catch_.id!, true);
              
              return true;
            } else {
              await _log.error('Сервер вернул ошибку: ${responseData['error']}');
            }
          } else if (response.statusCode == 429) {
            // Обработка ошибки спама
            final responseData = json.decode(response.body);
            if (responseData['error'] == 'SPAM_DETECTED') {
              await _log.warning('Обнаружен спам: ${responseData['message']}');
              
              // Помечаем поимку как спам в локальной базе
              await _updateCatchStatus(catch_.id!, AppConfig.statusSpam, 'SPAM_DETECTED');
              
              return false; // Не повторяем попытки для спама
            } else {
              await _log.error('HTTP ошибка 429: ${response.body}');
            }
          } else {
            await _log.error('HTTP ошибка: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          await _log.error('Ошибка при отправке на сервер (попытка $attempt): $e');
          
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay);
          }
        }
      }

      await _log.error('Не удалось отправить поимку на сервер после $_maxRetries попыток');
      return false;
      
    } catch (e) {
      await _log.error('Критическая ошибка при отправке на сервер', e);
      return false;
    }
  }

  /// Синхронизировать все неотправленные поимки
  Future<void> syncPendingCatches() async {
    try {
      await _log.info('Начинаем синхронизацию неотправленных поимок с сервером');
      
      // Получаем все поимки, которые не были отправлены на сервер
      final pendingCatches = await _db.getCatchesNotSentToServer();
      
      if (pendingCatches.isEmpty) {
        await _log.info('Нет поимок для синхронизации с сервером');
        return;
      }

      await _log.info('Найдено ${pendingCatches.length} поимок для отправки на сервер');

      int successCount = 0;
      for (final catch_ in pendingCatches) {
        final success = await sendCatchToServer(catch_);
        if (success) {
          successCount++;
        }
        
        // Небольшая задержка между запросами
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await _log.info('Синхронизация завершена: $successCount/${pendingCatches.length} поимок отправлено на сервер');
      
    } catch (e) {
      await _log.error('Ошибка при синхронизации с сервером', e);
    }
  }

  /// Проверить состояние сервера
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=health_check'),
        headers: {
          'User-Agent': 'CyFishON/${AppConfig.version}',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      await _log.error('Ошибка проверки состояния сервера', e);
      return false;
    }
  }

  /// Получить статистику с сервера
  Future<Map<String, dynamic>?> getServerStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_statistics'),
        headers: {
          'User-Agent': 'CyFishON/${AppConfig.version}',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      
      return null;
    } catch (e) {
      await _log.error('Ошибка получения статистики с сервера', e);
      return null;
    }
  }

  /// Обновить статус отправки на сервер в локальной базе данных
  Future<void> _updateServerSentStatus(int catchId, bool sent) async {
    try {
      await _db.updateCatchServerSentStatus(catchId, sent);
    } catch (e) {
      await _log.error('Ошибка обновления статуса отправки на сервер', e);
    }
  }

  /// Обновить статус поимки в локальной базе данных
  Future<void> _updateCatchStatus(int catchId, String status, String? error) async {
    try {
      await _db.updateCatchStatus(catchId, status, lastError: error);
    } catch (e) {
      await _log.error('Ошибка обновления статуса поимки', e);
    }
  }

  /// Получить информацию об устройстве
  Future<String> _getDeviceInfo() async {
    try {
      // Здесь можно добавить более подробную информацию об устройстве
      return 'Flutter/${AppConfig.version}';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Запустить автоматическую синхронизацию
  void startAutoSync() {
    // Синхронизация отправки каждые 5 минут (как и для Telegram)
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        await syncPendingCatches();
      }
    });
    
    // Синхронизация получения данных с сервера каждые 30 секунд
    Timer.periodic(Duration(seconds: AppConfig.serverSyncIntervalSeconds), (timer) async {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        await syncFromServer();
      }
    });
  }

  /// Синхронизировать поимки с сервера
  Future<List<CatchRecord>> syncFromServer() async {
    try {
      await _log.info('Начинаем синхронизацию поимок с сервера');
      
      // Получаем поимки за последние 7 дней
      final dateFrom = DateTime.now().subtract(Duration(days: AppConfig.serverSyncDaysLimit));
      final dateFromStr = dateFrom.toIso8601String().substring(0, 19).replaceAll('T', ' ');
      
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_catches&date_from=$dateFromStr&limit=1000'),
        headers: {
          'User-Agent': 'CyFishON/${AppConfig.version}',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final serverCatches = data['data'] as List;
          await _log.info('Получено ${serverCatches.length} поимок с сервера');
          
          final newCatches = <CatchRecord>[];
          
          for (final serverCatch in serverCatches) {
            try {
              // Преобразуем данные с сервера в CatchRecord
              final catchRecord = _convertServerCatchToRecord(serverCatch);
              
              // Проверяем, есть ли уже такая поимка в локальной базе
              final existingCatches = await _db.getCatches();
              final exists = existingCatches.any((existing) => 
                _isSameCatch(existing, catchRecord)
              );
              
              if (!exists) {
                // Добавляем новую поимку в локальную базу
                final id = await _db.insertCatch(catchRecord);
                final newCatch = catchRecord.copyWith(id: id);
                newCatches.add(newCatch);
                
                await _log.info('Добавлена новая поимка с сервера: ${catchRecord.userName} - ${catchRecord.catchTypeDisplay}');
              }
            } catch (e) {
              await _log.warning('Ошибка обработки поимки с сервера: $e');
            }
          }
          
          if (newCatches.isNotEmpty) {
            await _log.info('Синхронизация завершена: добавлено ${newCatches.length} новых поимок');
            // Уведомляем UI об обновлении данных
            _notifications.notifyNewCatches(newCatches);
          } else {
            await _log.info('Синхронизация завершена: новых поимок нет');
          }
          
          return newCatches;
        } else {
          await _log.error('Сервер вернул ошибку при синхронизации: ${data['error']}');
        }
      } else {
        await _log.error('HTTP ошибка при синхронизации: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      await _log.error('Ошибка синхронизации с сервера', e);
      return [];
    }
  }

  /// Преобразовать данные с сервера в CatchRecord
  CatchRecord _convertServerCatchToRecord(Map<String, dynamic> serverData) {
    try {
      // Парсим timestamp из формата сервера
      final timestampStr = serverData['timestamp'].toString();
      final timestamp = DateTime.parse(timestampStr.contains('T') ? timestampStr : timestampStr.replaceAll(' ', 'T'));
      
      // Парсим created_at
      final createdAtStr = serverData['created_at'].toString();
      final createdAt = DateTime.parse(createdAtStr.contains('T') ? createdAtStr : createdAtStr.replaceAll(' ', 'T'));
      
      return CatchRecord(
        userId: serverData['user_id']?.toString() ?? 'server_user',
        userName: serverData['user_name'].toString(),
        catchType: serverData['catch_type'].toString(),
        latitude: double.parse(serverData['latitude'].toString()),
        longitude: double.parse(serverData['longitude'].toString()),
        timestamp: timestamp,
        telegramStatus: AppConfig.statusSent, // Поимки с сервера уже отправлены
        serverStatus: AppConfig.statusSent, // Поимка уже на сервере
        isSyncedFromServer: true, // Помечаем как синхронизированную с сервера
        createdAt: createdAt,
      );
    } catch (e) {
      _log.error('Ошибка парсинга данных с сервера: $e, данные: $serverData');
      rethrow;
    }
  }

  /// Проверить, одинаковые ли поимки (по времени, пользователю и координатам)
  bool _isSameCatch(CatchRecord local, CatchRecord server) {
    // Сравниваем по пользователю, времени (с точностью до минуты) и координатам (с точностью до 4 знаков)
    final timeDiff = (local.timestamp.millisecondsSinceEpoch - server.timestamp.millisecondsSinceEpoch).abs();
    final sameTime = timeDiff < 60000; // Разница менее минуты
    final sameUser = local.userName == server.userName;
    final sameLocation = (local.latitude - server.latitude).abs() < 0.0001 && 
                        (local.longitude - server.longitude).abs() < 0.0001;
    
    return sameTime && sameUser && sameLocation;
  }
}
