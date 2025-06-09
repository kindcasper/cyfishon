import '../config/app_config.dart';

/// Модель записи лога
class LogEntry {
  final int? id;
  final DateTime timestamp;
  final String level; // 'info', 'warning', 'error'
  final String message;
  final String? details;
  final DateTime createdAt;

  LogEntry({
    this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Создание из Map (из базы данных)
  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      level: map['level'] as String,
      message: map['message'] as String,
      details: map['details'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Преобразование в Map (для базы данных)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level,
      'message': message,
      'details': details,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Создание информационного лога
  factory LogEntry.info(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: AppConfig.logLevelInfo,
      message: message,
      details: details,
    );
  }

  /// Создание предупреждающего лога
  factory LogEntry.warning(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: AppConfig.logLevelWarning,
      message: message,
      details: details,
    );
  }

  /// Создание лога ошибки
  factory LogEntry.error(String message, [dynamic error]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: AppConfig.logLevelError,
      message: message,
      details: error?.toString(),
    );
  }

  /// Получить цвет для уровня лога
  int get levelColor {
    switch (level) {
      case AppConfig.logLevelInfo:
        return 0xFF4CAF50; // Зеленый
      case AppConfig.logLevelWarning:
        return 0xFFFF9800; // Оранжевый
      case AppConfig.logLevelError:
        return 0xFFF44336; // Красный
      default:
        return 0xFF9E9E9E; // Серый
    }
  }

  /// Получить иконку для уровня лога
  String get levelIcon {
    switch (level) {
      case AppConfig.logLevelInfo:
        return 'ℹ️';
      case AppConfig.logLevelWarning:
        return '⚠️';
      case AppConfig.logLevelError:
        return '❌';
      default:
        return '📝';
    }
  }

  /// Форматированное время
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  /// Форматированная дата
  String get formattedDate {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$day.$month.$year';
  }

  /// Полное форматированное время
  String get formattedDateTime => '${formattedDate} ${formattedTime}';

  @override
  String toString() {
    return 'LogEntry($level): $message${details != null ? ' - $details' : ''}';
  }
}
