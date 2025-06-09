import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';
import 'secure_storage_service.dart';
import 'log_service.dart';

/// Сервис для работы с API
class ApiService {
  static final LogService _log = LogService();
  
  /// Базовый URL API
  static String get baseUrl => AppConfig.serverUrl;
  
  /// Получить заголовки для запросов
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = await SecureStorageService.getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  /// Обработка ответа сервера
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['error'] ?? data['message'] ?? 'Ошибка сервера',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Ошибка обработки ответа сервера',
        statusCode: response.statusCode,
      );
    }
  }

  /// Регистрация пользователя
  static Future<AuthResponse> register(RegisterRequest request) async {
    try {
      await _log.info('Попытка регистрации пользователя', request.email);
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'action': 'register',
          ...request.toJson(),
        }),
      );

      final data = _handleResponse(response);
      final authResponse = AuthResponse.fromJson(data);
      
      if (authResponse.success) {
        await _log.info('Регистрация успешна', request.email);
      } else {
        await _log.error('Ошибка регистрации', authResponse.error ?? 'Неизвестная ошибка');
      }
      
      return authResponse;
    } on ApiException catch (e) {
      await _log.error('API ошибка при регистрации', e.message);
      return AuthResponse.error(e.message);
    } catch (e) {
      await _log.error('Ошибка при регистрации', e);
      return AuthResponse.error('Ошибка подключения к серверу');
    }
  }

  /// Вход пользователя
  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      await _log.info('Попытка входа пользователя', request.email);
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'action': 'login',
          ...request.toJson(),
        }),
      );

      final data = _handleResponse(response);
      final authResponse = AuthResponse.fromJson(data);
      
      if (authResponse.success) {
        await _log.info('Вход успешен', request.email);
      } else {
        await _log.error('Ошибка входа', authResponse.error ?? 'Неизвестная ошибка');
      }
      
      return authResponse;
    } on ApiException catch (e) {
      await _log.error('API ошибка при входе', e.message);
      return AuthResponse.error(e.message);
    } catch (e) {
      await _log.error('Ошибка при входе', e);
      return AuthResponse.error('Ошибка подключения к серверу');
    }
  }

  /// Восстановление пароля
  static Future<AuthResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      await _log.info('Запрос восстановления пароля', request.email);
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'action': 'forgot_password',
          ...request.toJson(),
        }),
      );

      final data = _handleResponse(response);
      final authResponse = AuthResponse.fromJson(data);
      
      if (authResponse.success) {
        await _log.info('Пароль отправлен на email', request.email);
      } else {
        await _log.error('Ошибка восстановления пароля', authResponse.error ?? 'Неизвестная ошибка');
      }
      
      return authResponse;
    } on ApiException catch (e) {
      await _log.error('API ошибка при восстановлении пароля', e.message);
      return AuthResponse.error(e.message);
    } catch (e) {
      await _log.error('Ошибка при восстановлении пароля', e);
      return AuthResponse.error('Ошибка подключения к серверу');
    }
  }

  /// Проверка токена
  static Future<AuthResponse> verifyToken() async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        return AuthResponse.error('Токен не найден');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(),
        body: json.encode({
          'action': 'verify_token',
        }),
      );

      final data = _handleResponse(response);
      return AuthResponse.fromJson(data);
    } catch (e) {
      await _log.error('Ошибка при проверке токена', e);
      return AuthResponse.error('Ошибка проверки токена');
    }
  }

  /// Выход пользователя
  static Future<bool> logout() async {
    try {
      await _log.info('Выход пользователя');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(),
        body: json.encode({
          'action': 'logout',
        }),
      );

      _handleResponse(response);
      return true;
    } catch (e) {
      await _log.error('Ошибка при выходе', e);
      return false;
    }
  }

  /// Получить профиль пользователя
  static Future<User?> getProfile() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(),
        body: json.encode({
          'action': 'get_profile',
        }),
      );

      final data = _handleResponse(response);
      if (data['success'] == true && data['user'] != null) {
        return User.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      await _log.error('Ошибка при получении профиля', e);
      return null;
    }
  }

  /// Обновить профиль пользователя
  static Future<bool> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'update_profile',
      };
      
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      final data = _handleResponse(response);
      return data['success'] == true;
    } catch (e) {
      await _log.error('Ошибка при обновлении профиля', e);
      return false;
    }
  }
}

/// Исключение API
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException: $message (код: $statusCode)';
}
