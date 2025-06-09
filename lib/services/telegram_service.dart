import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/catch_record.dart';
import 'log_service.dart';
import 'location_service.dart';

/// Сервис для отправки сообщений в Telegram
class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();

  final LogService _log = LogService();
  final http.Client _httpClient = http.Client();

  /// Отправить сообщение о поимке в Telegram группу
  Future<bool> sendMessage(CatchRecord record) async {
    try {
      await _log.logTelegramSendAttempt(record.id ?? 0);
      
      // Форматируем сообщение
      final message = formatMessage(record);
      
      // URL для отправки сообщения
      final url = Uri.parse(
        '${AppConfig.telegramApiUrl}${AppConfig.telegramBotToken}/sendMessage',
      );
      
      // Тело запроса
      final body = {
        'chat_id': AppConfig.telegramGroupId,
        'text': message,
        'parse_mode': 'HTML',
      };
      
      // Отправляем запрос с таймаутом
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: AppConfig.requestTimeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Превышен таймаут отправки');
        },
      );
      
      // Проверяем ответ
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['ok'] == true) {
          await _log.logTelegramSendSuccess(record.id ?? 0);
          return true;
        } else {
          final error = responseData['description'] ?? 'Неизвестная ошибка';
          await _log.logTelegramSendError(record.id ?? 0, error);
          return false;
        }
      } else {
        await _log.logTelegramSendError(
          record.id ?? 0,
          'HTTP ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } on TimeoutException catch (e) {
      await _log.logTelegramSendError(
        record.id ?? 0,
        'Таймаут: ${e.message}',
      );
      return false;
    } catch (e) {
      await _log.logTelegramSendError(record.id ?? 0, e.toString());
      return false;
    }
  }

  /// Форматировать сообщение для отправки
  String formatMessage(CatchRecord record) {
    // Форматируем координаты
    final locationService = LocationService();
    final formattedLat = locationService.formatCoordinate(record.latitude, true);
    final formattedLon = locationService.formatCoordinate(record.longitude, false);
    
    // Собираем сообщение
    final lines = <String>[
      'Есть контакт от ${record.userName}; координаты',
      formattedLat,
      formattedLon,
    ];
    
    // Добавляем суффикс если нужно
    if (record.telegramSuffix.isNotEmpty) {
      lines.add(record.telegramSuffix);
    }
    
    return lines.join('\n');
  }

  /// Проверить доступность Telegram API
  Future<bool> checkConnection() async {
    try {
      final url = Uri.parse(
        '${AppConfig.telegramApiUrl}${AppConfig.telegramBotToken}/getMe',
      );
      
      final response = await _httpClient.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Таймаут проверки соединения');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      
      return false;
    } catch (e) {
      await _log.warning('Ошибка проверки Telegram API', e.toString());
      return false;
    }
  }

  /// Закрыть HTTP клиент
  void dispose() {
    _httpClient.close();
  }
}
