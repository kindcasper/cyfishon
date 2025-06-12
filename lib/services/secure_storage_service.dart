import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';

/// Статус аккаунта
enum AccountStatus {
  active,
  passwordReset,
  expired,
}

/// Локальный аккаунт
class LocalAccount {
  final int userId;
  final String userName;
  final String userEmail;
  final String? token;
  final AccountStatus status;
  final DateTime lastLogin;

  LocalAccount({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.token,
    this.status = AccountStatus.active,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'token': token,
      'status': status.name,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory LocalAccount.fromJson(Map<String, dynamic> json) {
    return LocalAccount(
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      token: json['token'],
      status: AccountStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AccountStatus.active,
      ),
      lastLogin: DateTime.parse(json['lastLogin']),
    );
  }

  /// Создать User объект из LocalAccount
  User toUser() {
    return User(
      id: userId,
      name: userName,
      email: userEmail,
      createdAt: lastLogin, // Используем lastLogin как приблизительную дату создания
    );
  }

  /// Создать копию с обновленными данными
  LocalAccount copyWith({
    String? userName,
    String? userEmail,
    String? token,
    AccountStatus? status,
    DateTime? lastLogin,
  }) {
    return LocalAccount(
      userId: userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      token: token ?? this.token,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

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

  // Ключи для хранения множественных аккаунтов
  static const String _accountsListKey = 'accounts_list';
  static const String _activeAccountIdKey = 'active_account_id';

  // Старые ключи для совместимости
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  /// Получить список всех аккаунтов
  static Future<List<LocalAccount>> getAllAccounts() async {
    final accountsJson = await _storage.read(key: _accountsListKey);
    if (accountsJson == null || accountsJson.isEmpty) {
      // Проверяем старый формат для миграции
      return await _migrateOldAccount();
    }

    try {
      final List<dynamic> accountsList = json.decode(accountsJson);
      return accountsList
          .map((json) => LocalAccount.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Сохранить список аккаунтов
  static Future<void> _saveAccountsList(List<LocalAccount> accounts) async {
    final accountsJson = json.encode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _accountsListKey, value: accountsJson);
  }

  /// Получить активный аккаунт
  static Future<LocalAccount?> getActiveAccount() async {
    final activeAccountIdStr = await _storage.read(key: _activeAccountIdKey);
    if (activeAccountIdStr == null) {
      return null;
    }

    final activeAccountId = int.tryParse(activeAccountIdStr);
    if (activeAccountId == null) {
      return null;
    }

    final accounts = await getAllAccounts();
    return accounts.where((a) => a.userId == activeAccountId).firstOrNull;
  }

  /// Установить активный аккаунт
  static Future<void> setActiveAccount(int userId) async {
    await _storage.write(key: _activeAccountIdKey, value: userId.toString());
  }

  /// Добавить или обновить аккаунт
  static Future<void> saveAccount(LocalAccount account) async {
    final accounts = await getAllAccounts();
    
    // Удаляем существующий аккаунт с таким же userId
    accounts.removeWhere((a) => a.userId == account.userId);
    
    // Добавляем новый/обновленный аккаунт
    accounts.add(account);
    
    // Сортируем по времени последнего входа
    accounts.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
    
    await _saveAccountsList(accounts);
    await setActiveAccount(account.userId);
  }

  /// Удалить аккаунт
  static Future<void> removeAccount(int userId) async {
    final accounts = await getAllAccounts();
    accounts.removeWhere((a) => a.userId == userId);
    await _saveAccountsList(accounts);

    // Если удаляем активный аккаунт, сбрасываем активный
    final activeAccount = await getActiveAccount();
    if (activeAccount?.userId == userId) {
      await _storage.delete(key: _activeAccountIdKey);
    }
  }

  /// Обновить статус аккаунта
  static Future<void> updateAccountStatus(int userId, AccountStatus status) async {
    final accounts = await getAllAccounts();
    final accountIndex = accounts.indexWhere((a) => a.userId == userId);
    
    if (accountIndex != -1) {
      accounts[accountIndex] = accounts[accountIndex].copyWith(status: status);
      await _saveAccountsList(accounts);
    }
  }

  /// Обновить токен аккаунта
  static Future<void> updateAccountToken(int userId, String token) async {
    final accounts = await getAllAccounts();
    final accountIndex = accounts.indexWhere((a) => a.userId == userId);
    
    if (accountIndex != -1) {
      accounts[accountIndex] = accounts[accountIndex].copyWith(
        token: token,
        status: AccountStatus.active,
        lastLogin: DateTime.now(),
      );
      await _saveAccountsList(accounts);
    }
  }

  /// Проверить, есть ли активный аккаунт
  static Future<bool> hasActiveAccount() async {
    final activeAccount = await getActiveAccount();
    return activeAccount != null && activeAccount.status == AccountStatus.active;
  }

  /// Очистить все данные авторизации
  static Future<void> clearAllAuthData() async {
    await Future.wait([
      _storage.delete(key: _accountsListKey),
      _storage.delete(key: _activeAccountIdKey),
      // Очищаем и старые ключи для совместимости
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _userEmailKey),
    ]);
  }

  /// Миграция старого формата аккаунта
  static Future<List<LocalAccount>> _migrateOldAccount() async {
    final token = await _storage.read(key: _tokenKey);
    final userIdStr = await _storage.read(key: _userIdKey);
    final userName = await _storage.read(key: _userNameKey);
    final userEmail = await _storage.read(key: _userEmailKey);

    if (token != null && userIdStr != null && userName != null && userEmail != null) {
      final userId = int.tryParse(userIdStr);
      if (userId != null) {
        final oldAccount = LocalAccount(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          token: token,
          status: AccountStatus.active,
          lastLogin: DateTime.now(),
        );

        // Сохраняем в новом формате
        await saveAccount(oldAccount);
        
        // Удаляем старые ключи
        await Future.wait([
          _storage.delete(key: _tokenKey),
          _storage.delete(key: _userIdKey),
          _storage.delete(key: _userNameKey),
          _storage.delete(key: _userEmailKey),
        ]);

        return [oldAccount];
      }
    }

    return [];
  }

  // Методы для обратной совместимости
  
  /// Получить токен активного аккаунта
  static Future<String?> getAuthToken() async {
    final activeAccount = await getActiveAccount();
    return activeAccount?.token;
  }

  /// Получить ID активного пользователя
  static Future<int?> getUserId() async {
    final activeAccount = await getActiveAccount();
    return activeAccount?.userId;
  }

  /// Получить имя активного пользователя
  static Future<String?> getUserName() async {
    final activeAccount = await getActiveAccount();
    return activeAccount?.userName;
  }

  /// Получить email активного пользователя
  static Future<String?> getUserEmail() async {
    final activeAccount = await getActiveAccount();
    return activeAccount?.userEmail;
  }

  /// Проверить, авторизован ли пользователь (обратная совместимость)
  static Future<bool> isLoggedIn() async {
    return await hasActiveAccount();
  }

  /// Сохранить данные пользователя (обратная совместимость)
  static Future<void> saveUserData({
    required int userId,
    required String userName,
    required String userEmail,
  }) async {
    final token = await getAuthToken();
    final account = LocalAccount(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      token: token,
      status: AccountStatus.active,
      lastLogin: DateTime.now(),
    );
    await saveAccount(account);
  }

  /// Сохранить токен авторизации (обратная совместимость)
  static Future<void> saveAuthToken(String token) async {
    final activeAccount = await getActiveAccount();
    if (activeAccount != null) {
      await updateAccountToken(activeAccount.userId, token);
    }
  }

  /// Очистить данные авторизации (обратная совместимость)
  static Future<void> clearAuthData() async {
    final activeAccount = await getActiveAccount();
    if (activeAccount != null) {
      await removeAccount(activeAccount.userId);
    }
  }

  /// Получить все данные пользователя (обратная совместимость)
  static Future<Map<String, String?>> getAllUserData() async {
    final activeAccount = await getActiveAccount();
    return {
      'token': activeAccount?.token,
      'userId': activeAccount?.userId.toString(),
      'userName': activeAccount?.userName,
      'userEmail': activeAccount?.userEmail,
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
