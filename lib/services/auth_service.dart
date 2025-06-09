import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'log_service.dart';
import 'user_service.dart';

/// Сервис авторизации
class AuthService {
  static final LogService _log = LogService();
  static User? _currentUser;
  
  /// Получить текущего пользователя
  static User? get currentUser => _currentUser;
  
  /// Проверить, авторизован ли пользователь
  static Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Проверяем, не истек ли токен
    try {
      if (JwtDecoder.isExpired(token)) {
        await _log.info('Токен истек, требуется повторная авторизация');
        await logout();
        return false;
      }
      return true;
    } catch (e) {
      await _log.error('Ошибка при проверке токена', e);
      await logout();
      return false;
    }
  }
  
  /// Автоматический вход при запуске приложения
  static Future<bool> autoLogin() async {
    try {
      if (!await isLoggedIn()) {
        return false;
      }
      
      // Проверяем токен на сервере
      final response = await ApiService.verifyToken();
      if (response.success && response.user != null) {
        _currentUser = response.user;
        await _log.info('Автоматический вход выполнен', response.user!.email);
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      await _log.error('Ошибка автоматического входа', e);
      await logout();
      return false;
    }
  }
  
  /// Регистрация нового пользователя
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Валидация данных
      final validation = _validateRegistrationData(name, email, password);
      if (!validation.isValid) {
        return AuthResult.error(validation.error!);
      }
      
      final request = RegisterRequest(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      final response = await ApiService.register(request);
      
      if (response.success && response.token != null && response.user != null) {
        // Сохраняем данные авторизации
        await _saveAuthData(response.token!, response.user!);
        _currentUser = response.user;
        
        // Сбрасываем кэшированный user_id для использования нового ID пользователя
        UserService().resetUserId();
        
        return AuthResult.success(
          user: response.user!,
          message: response.message ?? 'Регистрация успешна',
        );
      } else {
        return AuthResult.error(response.error ?? 'Ошибка регистрации');
      }
    } catch (e) {
      await _log.error('Ошибка при регистрации', e);
      return AuthResult.error('Ошибка подключения к серверу');
    }
  }
  
  /// Вход пользователя
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Валидация данных
      final validation = _validateLoginData(email, password);
      if (!validation.isValid) {
        return AuthResult.error(validation.error!);
      }
      
      final request = LoginRequest(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      final response = await ApiService.login(request);
      
      if (response.success && response.token != null && response.user != null) {
        // Сохраняем данные авторизации
        await _saveAuthData(response.token!, response.user!);
        _currentUser = response.user;
        
        // Сбрасываем кэшированный user_id для использования нового ID пользователя
        UserService().resetUserId();
        
        return AuthResult.success(
          user: response.user!,
          message: response.message ?? 'Вход выполнен успешно',
        );
      } else {
        return AuthResult.error(response.error ?? 'Неверный email или пароль');
      }
    } catch (e) {
      await _log.error('Ошибка при входе', e);
      return AuthResult.error('Ошибка подключения к серверу');
    }
  }
  
  /// Восстановление пароля
  static Future<AuthResult> forgotPassword({
    required String email,
  }) async {
    try {
      // Валидация email
      if (!_isValidEmail(email)) {
        return AuthResult.error('Введите корректный email');
      }
      
      final request = ForgotPasswordRequest(
        email: email.trim().toLowerCase(),
      );
      
      final response = await ApiService.forgotPassword(request);
      
      if (response.success) {
        return AuthResult.success(
          message: response.message ?? 'Новый пароль отправлен на email',
        );
      } else {
        return AuthResult.error(response.error ?? 'Ошибка восстановления пароля');
      }
    } catch (e) {
      await _log.error('Ошибка при восстановлении пароля', e);
      return AuthResult.error('Ошибка подключения к серверу');
    }
  }
  
  /// Выход пользователя
  static Future<void> logout() async {
    try {
      // Уведомляем сервер о выходе
      await ApiService.logout();
    } catch (e) {
      await _log.error('Ошибка при уведомлении сервера о выходе', e);
    } finally {
      // Очищаем локальные данные в любом случае
      await SecureStorageService.clearAuthData();
      _currentUser = null;
      
      // Сбрасываем кэшированный user_id при выходе
      UserService().resetUserId();
      
      await _log.info('Пользователь вышел из системы');
    }
  }
  
  /// Получить профиль пользователя
  static Future<User?> getProfile() async {
    try {
      final user = await ApiService.getProfile();
      if (user != null) {
        _currentUser = user;
        // Обновляем сохраненные данные
        await SecureStorageService.saveUserData(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
        );
      }
      return user;
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
      final success = await ApiService.updateProfile(
        name: name,
        email: email,
      );
      
      if (success) {
        // Обновляем локальные данные
        await getProfile();
      }
      
      return success;
    } catch (e) {
      await _log.error('Ошибка при обновлении профиля', e);
      return false;
    }
  }
  
  /// Сохранить данные авторизации
  static Future<void> _saveAuthData(String token, User user) async {
    await Future.wait([
      SecureStorageService.saveAuthToken(token),
      SecureStorageService.saveUserData(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
      ),
    ]);
  }
  
  /// Валидация данных регистрации
  static ValidationResult _validateRegistrationData(String name, String email, String password) {
    if (name.trim().isEmpty) {
      return ValidationResult.error('Введите имя');
    }
    
    if (name.trim().length < 2) {
      return ValidationResult.error('Имя должно содержать минимум 2 символа');
    }
    
    if (!_isValidEmail(email)) {
      return ValidationResult.error('Введите корректный email');
    }
    
    if (password.isEmpty) {
      return ValidationResult.error('Введите пароль');
    }
    
    return ValidationResult.valid();
  }
  
  /// Валидация данных входа
  static ValidationResult _validateLoginData(String email, String password) {
    if (!_isValidEmail(email)) {
      return ValidationResult.error('Введите корректный email');
    }
    
    if (password.isEmpty) {
      return ValidationResult.error('Введите пароль');
    }
    
    return ValidationResult.valid();
  }
  
  /// Проверка корректности email
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
  }
}

/// Результат операции авторизации
class AuthResult {
  final bool success;
  final User? user;
  final String? message;
  final String? error;

  const AuthResult._({
    required this.success,
    this.user,
    this.message,
    this.error,
  });

  /// Успешный результат
  factory AuthResult.success({
    User? user,
    String? message,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      message: message,
    );
  }

  /// Ошибка
  factory AuthResult.error(String error) {
    return AuthResult._(
      success: false,
      error: error,
    );
  }
}

/// Результат валидации
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult._({
    required this.isValid,
    this.error,
  });

  /// Валидация прошла успешно
  factory ValidationResult.valid() {
    return const ValidationResult._(isValid: true);
  }

  /// Ошибка валидации
  factory ValidationResult.error(String error) {
    return ValidationResult._(
      isValid: false,
      error: error,
    );
  }
}
