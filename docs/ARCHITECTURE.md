# Архитектура CyFishON

## 🏗️ Общий подход

Приложение построено по принципу **Offline-First** с простой модульной архитектурой.

## 📁 Структура проекта

```
cyfishon/
├── lib/
│   ├── main.dart              # Точка входа
│   ├── app.dart               # Конфигурация приложения
│   ├── config/
│   │   └── app_config.dart    # Константы и настройки
│   ├── models/
│   │   ├── catch_record.dart  # Модель поимки
│   │   └── log_entry.dart     # Модель лога
│   ├── screens/
│   │   ├── splash_screen.dart # Экран загрузки
│   │   ├── name_input_screen.dart # Ввод имени
│   │   ├── home_screen.dart   # Главный экран
│   │   ├── history_screen.dart # История поимок
│   │   ├── map_screen.dart    # Карта (заглушка)
│   │   ├── logs_screen.dart   # Логи
│   │   └── settings_screen.dart # Настройки
│   ├── services/
│   │   ├── location_service.dart # GPS координаты
│   │   ├── database_service.dart # SQLite база
│   │   ├── telegram_service.dart # Telegram API
│   │   ├── sync_service.dart  # Синхронизация
│   │   ├── log_service.dart   # Логирование
│   │   ├── compass_service.dart # Компас и направление
│   │   └── server_sync_service.dart # Синхронизация с сервером
│   └── widgets/
│       ├── catch_button.dart  # Кнопка поимки
│       ├── status_indicator.dart # Индикатор статуса
│       ├── bottom_nav.dart    # Нижняя навигация
│       └── map_widgets.dart   # Виджеты карты
```

## 🔄 Поток данных

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   UI Layer  │ ──> │  Services   │ ──> │  Database   │
│  (Screens)  │ <── │   Layer     │ <── │   (SQLite)  │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  External   │
                    │    APIs     │
                    │ (Telegram)  │
                    └─────────────┘
```

## 💾 База данных

### Таблица: catches (версия 3)
```sql
CREATE TABLE catches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  user_id TEXT NOT NULL,           -- НОВОЕ: уникальный ID пользователя
  user_name TEXT NOT NULL,         -- отображаемое имя (может изменяться)
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  catch_type TEXT NOT NULL, -- 'fishon', 'double', 'triple'
  telegram_status TEXT DEFAULT 'pending', -- 'pending', 'sent', 'failed'
  server_status TEXT DEFAULT 'pending',
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  is_synced_from_server INTEGER DEFAULT 0, -- флаг синхронизации с сервера
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Индексы для быстрого поиска
CREATE INDEX idx_catches_user_id ON catches(user_id);
CREATE INDEX idx_catches_user_name ON catches(user_name);
CREATE INDEX idx_catches_timestamp ON catches(timestamp DESC);
```

## 🆔 Система уникальных ID пользователей

### Принцип работы
- **user_id** - постоянный уникальный идентификатор устройства (например: `user_a6912f15`)
- **user_name** - отображаемое имя пользователя (может изменяться)
- **Все операции фильтрации и поиска** должны использовать `user_id`, а не `user_name`

### Генерация user_id
```dart
// UserService генерирует ID на основе характеристик устройства
final deviceInfo = await DeviceInfoPlugin().androidInfo; // или iosInfo
final deviceId = '${deviceInfo.id}-${deviceInfo.model}-${deviceInfo.brand}';
final hash = sha256.convert(utf8.encode(deviceId)).toString();
final userId = 'user_${hash.substring(0, 8)}'; // user_a6912f15
```

### ⚠️ ВАЖНО: Правила работы с пользователями

#### ✅ ПРАВИЛЬНО - используйте user_id:
```dart
// Фильтрация поимок конкретного пользователя
final catches = await db.getCatches(userId: currentUserId);

// Определение "моей" поимки
final isMyCatch = catch.userId == currentUserId;

// Поиск в базе данных
WHERE user_id = ?
```

#### ❌ НЕПРАВИЛЬНО - НЕ используйте user_name:
```dart
// НЕ ДЕЛАЙТЕ ТАК - имя может измениться!
final catches = await db.getCatches(userName: currentUserName);
final isMyCatch = catch.userName == currentUserName;
WHERE user_name = ?
```

### Миграция данных
При обновлении с версии 2 до версии 3:
```sql
-- Добавляем поле user_id
ALTER TABLE catches ADD COLUMN user_id TEXT DEFAULT "";

-- Обновляем существующие записи
UPDATE catches SET user_id = "legacy_" || user_name WHERE user_id = "";
```

### Таблица: logs
```sql
CREATE TABLE logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  level TEXT NOT NULL, -- 'info', 'warning', 'error'
  message TEXT NOT NULL,
  details TEXT,
  created_at INTEGER NOT NULL
);
```

## 🔧 Сервисы

### LocationService
```dart
class LocationService {
  // Получение текущих координат
  Future<Position?> getCurrentLocation();
  
  // Форматирование координат в градусы°минуты.тысячные′
  String formatCoordinate(double coordinate, bool isLatitude);
  
  // Проверка разрешений
  Future<bool> checkPermissions();
}
```

### DatabaseService
```dart
class DatabaseService {
  // Singleton паттерн
  static final DatabaseService _instance = DatabaseService._();
  
  // Операции с поимками
  Future<int> insertCatch(CatchRecord record);
  Future<List<CatchRecord>> getCatches({String? userName});
  Future<void> updateCatchStatus(int id, String status);
  
  // Операции с логами
  Future<void> insertLog(LogEntry log);
  Future<List<LogEntry>> getLogs({int? limit});
  Future<void> clearOldLogs(); // Удаление старше 30 дней
}
```

### TelegramService
```dart
class TelegramService {
  // Отправка сообщения в группу
  Future<bool> sendMessage(CatchRecord record);
  
  // Форматирование сообщения
  String formatMessage(CatchRecord record);
  
  // Проверка доступности API
  Future<bool> checkConnection();
}
```

### SyncService
```dart
class SyncService {
  Timer? _syncTimer;
  
  // Запуск фоновой синхронизации
  void startSync();
  
  // Остановка синхронизации
  void stopSync();
  
  // Синхронизация всех pending записей
  Future<void> syncPendingCatches();
  
  // Проверка интернета
  Future<bool> hasInternetConnection();
}
```

### CompassService
```dart
class CompassService {
  // Проверка доступности компаса
  Future<bool> isCompassAvailable();
  
  // Поток данных направления (в градусах)
  Stream<double> get headingStream;
  
  // Запуск прослушивания компаса
  Future<void> startListening();
  
  // Остановка прослушивания
  Future<void> stopListening();
}
```

### ServerSyncService
```dart
class ServerSyncService {
  // Синхронизация поимок с сервера
  Future<void> syncFromServer();
  
  // Отправка поимок на сервер
  Future<void> syncToServer();
  
  // Получение всех поимок с сервера
  Future<List<CatchRecord>> fetchCatchesFromServer();
  
  // Отправка поимки на сервер
  Future<bool> sendCatchToServer(CatchRecord catch);
}
```

## 🎨 UI компоненты

### Навигация
```dart
// Bottom Navigation Bar
┌─────┬─────┬─────┬─────┐
│  🎣 │  📋 │  🗺️ │  📄 │
├─────┼─────┼─────┼─────┤
│Home │Hist │ Map │Logs │
└─────┴─────┴─────┴─────┘
```

### Главный экран
```
┌─────────────────────────┐
│ 📍 Координаты      10с  │
│ 34°56.789'N            │
│ 33°12.345'E            │
├─────────────────────────┤
│ Последние поимки:      │
│ 🟢 FishON - 5 мин      │
│ 🟡 Double - 15 мин     │
│ 🟢 Triple - 1 час      │
├─────────────────────────┤
│                         │
│   ┌─────────────┐      │
│   │   FishON    │      │
│   └─────────────┘      │
│   ┌─────────────┐      │
│   │   Double    │      │
│   └─────────────┘      │
│   ┌─────────────┐      │
│   │ Triple EPTA │      │
│   └─────────────┘      │
│                         │
└─────────────────────────┘
```

## 🔄 Жизненный цикл приложения

1. **Запуск**
   - Проверка первого запуска
   - Если нет имени → NameInputScreen
   - Если есть имя → HomeScreen

2. **Инициализация**
   - Создание/открытие БД
   - Запрос разрешений GPS
   - Запуск SyncService

3. **Работа**
   - Локальное сохранение всех действий
   - Фоновая синхронизация каждые 10 сек
   - Обновление UI через setState/StreamBuilder

4. **Завершение**
   - Остановка таймеров
   - Закрытие БД
   - Сохранение состояния

## 🛡️ Обработка ошибок

### Уровни ошибок:
1. **Критические** - приложение не может работать (нет БД)
2. **Важные** - функция недоступна (нет GPS)
3. **Информационные** - временные проблемы (нет интернета)

### Стратегия:
- Критические → показать экран ошибки
- Важные → показать предупреждение, продолжить работу
- Информационные → логировать, работать офлайн

## 📱 Платформенные особенности

### Android
- Минимальная версия: API 21 (Android 5.0)
- Разрешения: INTERNET, ACCESS_FINE_LOCATION

### iOS
- Минимальная версия: iOS 11.0
- Info.plist: NSLocationWhenInUseUsageDescription

## 🚀 Оптимизация

- Ленивая загрузка данных
- Пагинация в истории (по 50 записей)
- Кеширование последних координат
- Батчинг при синхронизации

---

**Важно**: При изменении архитектуры обязательно обновляйте этот документ!
