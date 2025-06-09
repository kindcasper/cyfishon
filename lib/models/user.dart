/// Модель пользователя
class User {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.isActive = true,
  });

  /// Создание пользователя из JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Копирование с изменениями
  User copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Модель ответа авторизации
class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? message;
  final String? error;

  const AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.error,
  });

  /// Создание из JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  /// Успешный ответ
  factory AuthResponse.success({
    required String token,
    required User user,
    String? message,
  }) {
    return AuthResponse(
      success: true,
      token: token,
      user: user,
      message: message,
    );
  }

  /// Ошибка
  factory AuthResponse.error(String error) {
    return AuthResponse(
      success: false,
      error: error,
    );
  }
}

/// Модель запроса регистрации
class RegisterRequest {
  final String name;
  final String email;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }
}

/// Модель запроса входа
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Модель запроса восстановления пароля
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({
    required this.email,
  });

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
