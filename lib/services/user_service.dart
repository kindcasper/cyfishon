import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'log_service.dart';
import 'auth_service.dart';

/// Сервис для работы с пользователем и уникальным ID
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final LogService _log = LogService();
  
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyDeviceId = 'device_id';

  String? _userId;
  String? _userName;
  String? _deviceId;

  /// Получить уникальный ID пользователя
  Future<String> getUserId() async {
    try {
      // Проверяем, авторизован ли пользователь
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Используем ID авторизованного пользователя
        _userId = 'auth_${currentUser.id}';
        await _log.info('Используется ID авторизованного пользователя: $_userId');
        return _userId!;
      }
      
      // Если пользователь не авторизован, используем device-based ID (для совместимости)
      if (_userId != null) return _userId!;

      final prefs = await SharedPreferences.getInstance();
      
      // Проверяем, есть ли уже сохраненный device-based ID
      _userId = prefs.getString(_keyUserId);
      
      if (_userId == null) {
        // Генерируем новый ID на основе device ID
        final deviceId = await _getDeviceId();
        _userId = _generateUserId(deviceId);
        
        // Сохраняем ID
        await prefs.setString(_keyUserId, _userId!);
        await _log.info('Сгенерирован новый device-based ID пользователя: $_userId');
      } else {
        await _log.info('Загружен существующий device-based ID пользователя: $_userId');
      }
      
      return _userId!;
    } catch (e) {
      await _log.error('Ошибка получения ID пользователя', e);
      // Fallback ID в случае ошибки
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      return _userId!;
    }
  }

  /// Получить имя пользователя для отображения
  Future<String?> getUserName() async {
    if (_userName != null) return _userName;

    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString(_keyUserName);
      return _userName;
    } catch (e) {
      await _log.error('Ошибка получения имени пользователя', e);
      return null;
    }
  }

  /// Установить имя пользователя для отображения
  Future<void> setUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, name);
      _userName = name;
      await _log.info('Имя пользователя обновлено: $name');
    } catch (e) {
      await _log.error('Ошибка сохранения имени пользователя', e);
      rethrow;
    }
  }

  /// Проверить, установлено ли имя пользователя
  Future<bool> hasUserName() async {
    final name = await getUserName();
    return name != null && name.isNotEmpty;
  }

  /// Получить Device ID устройства
  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Проверяем, есть ли уже сохраненный device ID
      _deviceId = prefs.getString(_keyDeviceId);
      
      if (_deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();
        
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          // Используем комбинацию уникальных полей Android
          _deviceId = '${androidInfo.id}_${androidInfo.fingerprint}_${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          // Используем identifierForVendor для iOS
          _deviceId = iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          // Fallback для других платформ
          _deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        // Сохраняем device ID
        await prefs.setString(_keyDeviceId, _deviceId!);
        await _log.info('Сгенерирован Device ID: $_deviceId');
      }
      
      return _deviceId!;
    } catch (e) {
      await _log.error('Ошибка получения Device ID', e);
      // Fallback device ID
      _deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  /// Сгенерировать уникальный ID пользователя на основе device ID
  String _generateUserId(String deviceId) {
    // Создаем хеш от device ID для получения короткого уникального ID
    final bytes = utf8.encode(deviceId);
    final digest = sha256.convert(bytes);
    
    // Берем первые 8 символов хеша для компактности
    final shortHash = digest.toString().substring(0, 8);
    
    return 'user_$shortHash';
  }

  /// Получить информацию об устройстве для отладки
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final deviceId = await _getDeviceId();
      final userId = await getUserId();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'device_id': deviceId,
          'user_id': userId,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
          'device_id': deviceId,
          'user_id': userId,
        };
      } else {
        return {
          'platform': 'Unknown',
          'device_id': deviceId,
          'user_id': userId,
        };
      }
    } catch (e) {
      await _log.error('Ошибка получения информации об устройстве', e);
      return {
        'platform': 'Error',
        'error': e.toString(),
      };
    }
  }

  /// Сбросить кэшированный user_id (вызывается при смене авторизации)
  void resetUserId() {
    _userId = null;
    _log.info('Кэшированный user_id сброшен');
  }

  /// Очистить данные пользователя (для отладки)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyDeviceId);
      
      _userId = null;
      _userName = null;
      _deviceId = null;
      
      await _log.info('Данные пользователя очищены');
    } catch (e) {
      await _log.error('Ошибка очистки данных пользователя', e);
    }
  }
}
