# Система локализации CyFishON

## Обзор

Приложение CyFishON поддерживает многоязычность с помощью собственной системы локализации. В настоящее время поддерживаются следующие языки:

- 🇷🇺 **Русский** (по умолчанию)
- 🇺🇸 **Английский**

## Структура файлов

```
lib/l10n/
├── app_localizations.dart          # Абстрактный класс с определениями строк
├── app_localizations_ru.dart       # Русская локализация
├── app_localizations_en.dart       # Английская локализация
└── app_localizations_delegate.dart # Делегат локализации

lib/services/
└── locale_service.dart              # Сервис управления языком
```

## Архитектура

### 1. AppLocalizations (абстрактный класс)
Определяет все строки, используемые в приложении:

```dart
abstract class AppLocalizations {
  // Общие
  String get appName;
  String get ok;
  String get cancel;
  // ... остальные строки
}
```

### 2. Конкретные реализации
- `AppLocalizationsRu` - русские переводы
- `AppLocalizationsEn` - английские переводы

### 3. LocaleService
Управляет текущим языком приложения:
- Сохраняет выбранный язык в SharedPreferences
- Автоматически определяет язык системы при первом запуске
- Уведомляет виджеты об изменении языка

### 4. AppLocalizationsDelegate
Загружает соответствующую локализацию на основе выбранного языка.

## Использование в коде

### Получение переводов
```dart
// В виджете
final l10n = AppLocalizations.of(context);
Text(l10n.welcome); // Отобразит "Добро пожаловать" или "Welcome"
```

### Смена языка
```dart
final localeService = LocaleService();
await localeService.setLocale(Locale('en')); // Переключить на английский
```

## Категории строк

### 1. Общие (General)
- `appName`, `ok`, `cancel`, `save`, `delete`, `edit`, `close`, `back`, `next`
- `loading`, `error`, `success`, `warning`, `info`, `retry`, `yes`, `no`

### 2. Навигация (Navigation)
- `home`, `map`, `history`, `logs`, `settings`

### 3. Авторизация (Authentication)
- `welcome`, `login`, `register`, `logout`, `email`, `password`, `name`
- `confirmPassword`, `forgotPassword`, `createAccount`
- Сообщения об ошибках и успехе

### 4. Поимки (Catches)
- `fishOn`, `doubleFish`, `tripleFish`, `addCatch`, `catchType`
- `location`, `coordinates`, `accuracy`, `timestamp`, `fisherman`
- Статусы синхронизации

### 5. Карта (Map)
- `mapView`, `satellite`, `terrain`, `hybrid`, `myLocation`
- `centerMap`, `zoomIn`, `zoomOut`, `compass`, `bearing`, `distance`

### 6. Настройки (Settings)
- `generalSettings`, `language`, `notifications`, `sync`, `about`
- `version`, `developer`, `contact`, `privacy`, `terms`
- Настройки темы и синхронизации

### 7. Геолокация (Location)
- `locationPermission`, `locationPermissionDenied`, `gettingLocation`
- `locationError`, `locationAccuracy`, `gpsSignal`

### 8. Логи (Logs)
- `viewLogs`, `clearLogs`, `exportLogs`, `logLevel`
- `logInfo`, `logWarning`, `logError`

### 9. История (History)
- `catchHistory`, `filterBy`, `sortBy`, `ascending`, `descending`
- `today`, `yesterday`, `thisWeek`, `thisMonth`, `allTime`

### 10. Статистика (Statistics)
- `statistics`, `totalCatches`, `fishOnCount`, `doubleCount`, `tripleCount`
- `averagePerDay`, `bestDay`, `bestLocation`

### 11. Ошибки и сообщения (Errors and Messages)
- `connectionError`, `serverUnavailable`, `timeoutError`
- `dataCorrupted`, `permissionDenied`, `updateRequired`

### 12. Диалоги (Dialogs)
- `confirmDelete`, `confirmClear`, `confirmLogout`, `confirmExit`
- `unsavedChanges`, `discardChanges`, `saveChanges`

### 13. Время (Time)
- `now`, `minutesAgo`, `hoursAgo`, `daysAgo`, `weeksAgo`, `monthsAgo`, `yearsAgo`

### 14. Единицы измерения (Units)
- `meters`, `kilometers`, `feet`, `miles`, `degrees`
- `seconds`, `minutes`, `hours`, `days`

### 15. Направления (Directions)
- `north`, `south`, `east`, `west`
- `northeast`, `northwest`, `southeast`, `southwest`

## Добавление нового языка

### 1. Создать файл локализации
```dart
// lib/l10n/app_localizations_de.dart (для немецкого)
import 'app_localizations.dart';

class AppLocalizationsDe extends AppLocalizations {
  @override
  String get appName => 'CyFishON';
  
  @override
  String get welcome => 'Willkommen';
  
  // ... остальные переводы
}
```

### 2. Обновить делегат
```dart
// lib/l10n/app_localizations_delegate.dart
@override
bool isSupported(Locale locale) {
  return ['ru', 'en', 'de'].contains(locale.languageCode);
}

@override
Future<AppLocalizations> load(Locale locale) async {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'de':
      return AppLocalizationsDe();
    case 'ru':
    default:
      return AppLocalizationsRu();
  }
}
```

### 3. Обновить LocaleService
```dart
// lib/services/locale_service.dart
static const List<Locale> supportedLocales = [
  Locale('ru'),
  Locale('en'),
  Locale('de'), // Добавить новый язык
];

static const Map<String, String> languageNames = {
  'ru': 'Русский',
  'en': 'English',
  'de': 'Deutsch', // Добавить название
};
```

## Настройка языка в приложении

Пользователи могут изменить язык в настройках:
1. Открыть **Настройки**
2. В разделе **Пользователь** найти **Язык / Language**
3. Выбрать нужный язык из списка
4. Приложение автоматически перезагрузится с новым языком

## Автоматическое определение языка

При первом запуске приложение:
1. Проверяет сохраненный язык в SharedPreferences
2. Если язык не сохранен, определяет язык системы
3. Если язык системы не поддерживается, использует русский по умолчанию

## Технические детали

### Сохранение настроек
Выбранный язык сохраняется в SharedPreferences с ключом `selected_language`.

### Уведомления об изменениях
LocaleService наследует от ChangeNotifier и уведомляет виджеты об изменении языка.

### Динамическое обновление
Приложение использует ListenableBuilder для автоматического обновления интерфейса при смене языка.

## Рекомендации

### Для разработчиков
1. **Всегда используйте локализацию** вместо хардкода строк
2. **Группируйте связанные строки** по категориям
3. **Используйте понятные ключи** для строк
4. **Тестируйте на всех языках** перед релизом

### Для переводчиков
1. **Учитывайте контекст** использования строки
2. **Соблюдайте длину строк** для UI элементов
3. **Используйте консистентную терминологию**
4. **Тестируйте переводы** в реальном интерфейсе

## Будущие улучшения

1. **Добавление новых языков** (греческий, турецкий)
2. **Плюрализация** для правильных форм множественного числа
3. **Форматирование дат и чисел** по локали
4. **RTL поддержка** для арабского языка
5. **Автоматическая генерация** из JSON/ARB файлов
