import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Сервис для безопасного хранения данных
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Ключи для хранения
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  /// Сохранить токен авторизации
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Получить токен авторизации
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Удалить токен авторизации
  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Сохранить данные пользователя
  static Future<void> saveUserData({
    required int userId,
    required String userName,
    required String userEmail,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId.toString()),
      _storage.write(key: _userNameKey, value: userName),
      _storage.write(key: _userEmailKey, value: userEmail),
    ]);
  }

  /// Получить ID пользователя
  static Future<int?> getUserId() async {
    final userIdStr = await _storage.read(key: _userIdKey);
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  /// Получить имя пользователя
  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  /// Получить email пользователя
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Проверить, авторизован ли пользователь
  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Очистить все данные авторизации
  static Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _userEmailKey),
    ]);
  }

  /// Получить все данные пользователя
  static Future<Map<String, String?>> getAllUserData() async {
    final results = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _userIdKey),
      _storage.read(key: _userNameKey),
      _storage.read(key: _userEmailKey),
    ]);

    return {
      'token': results[0],
      'userId': results[1],
      'userName': results[2],
      'userEmail': results[3],
    };
  }

  /// Проверить, содержит ли хранилище данные
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Получить все ключи
  static Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  /// Очистить все данные
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
