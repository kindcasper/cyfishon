import '../config/app_config.dart';

/// Модель записи о поимке рыбы
class CatchRecord {
  final int? id;
  final DateTime timestamp;
  final String userName;
  final double latitude;
  final double longitude;
  final String catchType; // 'fishon', 'double', 'triple'
  final String telegramStatus; // 'pending', 'sent', 'failed'
  final String serverStatus; // 'pending', 'sent', 'failed'
  final int retryCount;
  final String? lastError;
  final bool isSyncedFromServer; // true если поимка получена с сервера
  final DateTime createdAt;
  final DateTime updatedAt;

  CatchRecord({
    this.id,
    required this.timestamp,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.catchType,
    this.telegramStatus = AppConfig.statusPending,
    this.serverStatus = AppConfig.statusPending,
    this.retryCount = 0,
    this.lastError,
    this.isSyncedFromServer = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Создание из Map (из базы данных)
  factory CatchRecord.fromMap(Map<String, dynamic> map) {
    return CatchRecord(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      userName: map['user_name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      catchType: map['catch_type'] as String,
      telegramStatus: map['telegram_status'] as String? ?? AppConfig.statusPending,
      serverStatus: map['server_status'] as String? ?? AppConfig.statusPending,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      isSyncedFromServer: (map['is_synced_from_server'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Преобразование в Map (для базы данных)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'user_name': userName,
      'latitude': latitude,
      'longitude': longitude,
      'catch_type': catchType,
      'telegram_status': telegramStatus,
      'server_status': serverStatus,
      'retry_count': retryCount,
      'last_error': lastError,
      'is_synced_from_server': isSyncedFromServer ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Копирование с изменениями
  CatchRecord copyWith({
    int? id,
    DateTime? timestamp,
    String? userName,
    double? latitude,
    double? longitude,
    String? catchType,
    String? telegramStatus,
    String? serverStatus,
    int? retryCount,
    String? lastError,
    bool? isSyncedFromServer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CatchRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      catchType: catchType ?? this.catchType,
      telegramStatus: telegramStatus ?? this.telegramStatus,
      serverStatus: serverStatus ?? this.serverStatus,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      isSyncedFromServer: isSyncedFromServer ?? this.isSyncedFromServer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Получить текст для отображения типа поимки
  String get catchTypeDisplay {
    switch (catchType) {
      case AppConfig.catchTypeFishOn:
        return 'FishON';
      case AppConfig.catchTypeDouble:
        return 'Double';
      case AppConfig.catchTypeTriple:
        return 'Triple ЕПТА!';
      default:
        return catchType;
    }
  }

  /// Получить суффикс для сообщения в Telegram
  String get telegramSuffix {
    switch (catchType) {
      case AppConfig.catchTypeFishOn:
        return '';
      case AppConfig.catchTypeDouble:
        return 'Double';
      case AppConfig.catchTypeTriple:
        return 'Triple ЕПТА!';
      default:
        return '';
    }
  }

  /// Проверка, отправлено ли в Telegram
  bool get isSentToTelegram => telegramStatus == AppConfig.statusSent;

  /// Проверка, есть ли ошибка отправки
  bool get hasError => telegramStatus == AppConfig.statusFailed;

  /// Проверка, ожидает ли отправки
  bool get isPending => telegramStatus == AppConfig.statusPending;

  /// Получить время, прошедшее с момента поимки
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} сек назад';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} д назад';
    }
  }

  @override
  String toString() {
    return 'CatchRecord(id: $id, userName: $userName, catchType: $catchType, '
        'lat: $latitude, lon: $longitude, status: $telegramStatus)';
  }
}
