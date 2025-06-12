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
  
  /// Проверить, авторизован ли пользователь (локально)
  static Future<bool> isLoggedIn() async {
    return await SecureStorageService.hasActiveAccount();
  }
  
  /// Автоматический вход при запуске приложения (офлайн режим)
  static Future<bool> autoLogin() async {
    try {
      // Получаем активный аккаунт из локального хранилища
      final activeAccount = await SecureStorageService.getActiveAccount();
      
      if (activeAccount == null) {
        await _log.info('Нет активного аккаунта для автоматического входа');
        return false;
      }

      // Проверяем статус аккаунта
      if (activeAccount.status != AccountStatus.active) {
        await _log.info('Аккаунт требует повторной авторизации', 
          'Статус: ${activeAccount.status.name}');
        return false;
      }

      // Авторизуем пользователя локально
      _currentUser = activeAccount.toUser();
      await _log.info('Автоматический вход выполнен (офлайн)', activeAccount.userEmail);

      // Запускаем фоновую проверку токена (если есть интернет)
      _backgroundTokenVerification(activeAccount);

      return true;
    } catch (e) {
      await _log.error('Ошибка автоматического входа', e);
      return false;
    }
  }

  /// Фоновая проверка токена на сервере
  static void _backgroundTokenVerification(LocalAccount account) async {
    try {
      if (account.token == null) return;

      // Проверяем, не истек ли токен локально
      if (JwtDecoder.isExpired(account.token!)) {
        await _log.info('Токен истек локально');
        await SecureStorageService.updateAccountStatus(
          account.userId, 
          AccountStatus.expired
        );
        return;
      }

      // Проверяем токен на сервере (в фоне)
      final response = await ApiService.verifyToken();
      if (!response.success) {
        await _log.info('Токен недействителен на сервере');
        await SecureStorageService.updateAccountStatus(
          account.userId, 
          AccountStatus.expired
        );
      } else {
        await _log.info('Токен подтвержден сервером');
        // Обновляем данные пользователя если они изменились
        if (response.user != null) {
          final updatedAccount = account.copyWith(
            userName: response.user!.name,
            userEmail: response.user!.email,
            lastLogin: DateTime.now(),
          );
          await SecureStorageService.saveAccount(updatedAccount);
          _currentUser = response.user;
        }
      }
    } catch (e) {
      // Ошибки фоновой проверки не критичны
      await _log.info('Фоновая проверка токена недоступна (нет интернета)');
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
        // Создаем локальный аккаунт
        final localAccount = LocalAccount(
          userId: response.user!.id,
          userName: response.user!.name,
          userEmail: response.user!.email,
          token: response.token,
          status: AccountStatus.active,
          lastLogin: DateTime.now(),
        );

        // Сохраняем аккаунт и делаем его активным
        await SecureStorageService.saveAccount(localAccount);
        _currentUser = response.user;
        
        // Сбрасываем кэшированный user_id для использования нового ID пользователя
        UserService().resetUserId();
        
        await _log.info('Регистрация успешна', response.user!.email);
        
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
        // Создаем или обновляем локальный аккаунт
        final localAccount = LocalAccount(
          userId: response.user!.id,
          userName: response.user!.name,
          userEmail: response.user!.email,
          token: response.token,
          status: AccountStatus.active,
          lastLogin: DateTime.now(),
        );

        // Сохраняем аккаунт и делаем его активным
        await SecureStorageService.saveAccount(localAccount);
        _currentUser = response.user;
        
        // Сбрасываем кэшированный user_id для использования нового ID пользователя
        UserService().resetUserId();
        
        await _log.info('Вход выполнен успешно', response.user!.email);
        
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

  /// Вход в существующий локальный аккаунт
  static Future<AuthResult> loginToLocalAccount(LocalAccount account) async {
    try {
      if (account.status == AccountStatus.passwordReset) {
        return AuthResult.error('Пароль был сброшен. Необходимо войти с новым паролем.');
      }

      if (account.status == AccountStatus.expired) {
        return AuthResult.error('Сессия истекла. Необходимо войти заново.');
      }

      // Устанавливаем аккаунт как активный
      await SecureStorageService.setActiveAccount(account.userId);
      
      // Обновляем время последнего входа
      final updatedAccount = account.copyWith(lastLogin: DateTime.now());
      await SecureStorageService.saveAccount(updatedAccount);
      
      _currentUser = account.toUser();
      
      // Сбрасываем кэшированный user_id для использования ID этого пользователя
      UserService().resetUserId();
      
      await _log.info('Вход в локальный аккаунт', account.userEmail);
      
      // Запускаем фоновую проверку токена
      _backgroundTokenVerification(account);
      
      return AuthResult.success(
        user: account.toUser(),
        message: 'Добро пожаловать, ${account.userName}!',
      );
    } catch (e) {
      await _log.error('Ошибка при входе в локальный аккаунт', e);
      return AuthResult.error('Ошибка входа в аккаунт');
    }
  }
  
  /// Восстановление пароля (требует интернет)
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
        // Находим локальный аккаунт с таким email и помечаем как требующий сброса пароля
        final accounts = await SecureStorageService.getAllAccounts();
        final accountIndex = accounts.indexWhere(
          (a) => a.userEmail.toLowerCase() == email.toLowerCase()
        );
        
        if (accountIndex != -1) {
          await SecureStorageService.updateAccountStatus(
            accounts[accountIndex].userId, 
            AccountStatus.passwordReset
          );
          await _log.info('Локальный аккаунт помечен как требующий сброса пароля', email);
        }
        
        return AuthResult.success(
          message: response.message ?? 'Новый пароль отправлен на email',
        );
      } else {
        return AuthResult.error(response.error ?? 'Ошибка восстановления пароля');
      }
    } catch (e) {
      await _log.error('Ошибка при восстановлении пароля', e);
      return AuthResult.error('Для сброса пароля необходимо подключение к интернету');
    }
  }
  
  /// Выход пользователя (переход к выбору аккаунта)
  static Future<void> logout() async {
    try {
      // Уведомляем сервер о выходе (если есть интернет)
      try {
        await ApiService.logout();
      } catch (e) {
        await _log.info('Не удалось уведомить сервер о выходе (нет интернета)');
      }
      
      // Сбрасываем активный аккаунт, но не удаляем его
      final activeAccount = await SecureStorageService.getActiveAccount();
      if (activeAccount != null) {
        await SecureStorageService.setActiveAccount(-1); // Сбрасываем активный аккаунт
      }
      
      _currentUser = null;
      
      // Сбрасываем кэшированный user_id при выходе
      UserService().resetUserId();
      
      await _log.info('Пользователь вышел из системы');
    } catch (e) {
      await _log.error('Ошибка при выходе', e);
    }
  }

  /// Полное удаление аккаунта с устройства
  static Future<void> removeAccount(int userId) async {
    try {
      await SecureStorageService.removeAccount(userId);
      
      // Если удаляем текущего пользователя, сбрасываем его
      if (_currentUser?.id == userId) {
        _currentUser = null;
        UserService().resetUserId();
      }
      
      await _log.info('Аккаунт удален с устройства', userId.toString());
    } catch (e) {
      await _log.error('Ошибка при удалении аккаунта', e);
    }
  }

  /// Получить все локальные аккаунты
  static Future<List<LocalAccount>> getAllLocalAccounts() async {
    return await SecureStorageService.getAllAccounts();
  }
  
  /// Получить профиль пользователя
  static Future<User?> getProfile() async {
    try {
      final user = await ApiService.getProfile();
      if (user != null) {
        _currentUser = user;
        
        // Обновляем локальный аккаунт
        final activeAccount = await SecureStorageService.getActiveAccount();
        if (activeAccount != null) {
          final updatedAccount = activeAccount.copyWith(
            userName: user.name,
            userEmail: user.email,
          );
          await SecureStorageService.saveAccount(updatedAccount);
        }
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
