/// Конфигурация приложения CyFishON
/// Все константы и настройки в одном месте
class AppConfig {
  // Версия приложения
  static const String version = '1.0.6';
  
  // Telegram API
  static const String telegramBotToken = '8017367144:AAEO257fAdCJ_ghankGbx0WVX2RZklQiwqE';
  static const String telegramGroupId = '-4881811622';
  static const String telegramApiUrl = 'https://api.telegram.org/bot';
  
  // Таймауты и интервалы
  static const int requestTimeoutSeconds = 10;
  static const int syncIntervalSeconds = 10;
  static const int defaultRetryMinutes = 5;
  static const int locationUpdateSeconds = 10;
  static const int serverSyncIntervalSeconds = 30;
  static const int serverSyncDaysLimit = 7;
  
  // Ограничения
  static const int maxUserNameLength = 13;
  static const int maxRecentCatches = 3;
  static const int logsRetentionDays = 30;
  
  // SharedPreferences ключи
  static const String keyUserName = 'user_name';
  static const String keyRetryInterval = 'retry_interval_minutes';
  static const String keyFirstLaunch = 'first_launch';
  
  // База данных
  static const String databaseName = 'cyfishon.db';
  static const int databaseVersion = 1;
  
  // Типы поимок
  static const String catchTypeFishOn = 'fishon';
  static const String catchTypeDouble = 'double';
  static const String catchTypeTriple = 'triple';
  
  // Статусы синхронизации
  static const String statusPending = 'pending';
  static const String statusSent = 'sent';
  static const String statusFailed = 'failed';
  
  // Уровни логирования
  static const String logLevelInfo = 'info';
  static const String logLevelWarning = 'warning';
  static const String logLevelError = 'error';
  
  // Форматирование
  static const String coordinateFormat = '%d°%06.3f′%s'; // Градусы°минуты.тысячные′направление
  
  // GPS настройки
  static const double requiredAccuracy = 50.0; // метры
  static const int maxLocationAttempts = 3;
  
  // Не создаем экземпляры этого класса
  AppConfig._();
}
