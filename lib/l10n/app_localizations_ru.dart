import 'app_localizations.dart';

/// Русская локализация
class AppLocalizationsRu extends AppLocalizations {
  // Общие
  @override
  String get appName => 'CyFishON';
  @override
  String get ok => 'ОК';
  @override
  String get cancel => 'Отмена';
  @override
  String get save => 'Сохранить';
  @override
  String get delete => 'Удалить';
  @override
  String get edit => 'Редактировать';
  @override
  String get close => 'Закрыть';
  @override
  String get back => 'Назад';
  @override
  String get next => 'Далее';
  @override
  String get loading => 'Загрузка...';
  @override
  String get error => 'Ошибка';
  @override
  String get success => 'Успешно';
  @override
  String get warning => 'Предупреждение';
  @override
  String get info => 'Информация';
  @override
  String get retry => 'Повторить';
  @override
  String get yes => 'Да';
  @override
  String get no => 'Нет';

  // Навигация
  @override
  String get home => 'Главная';
  @override
  String get map => 'Карта';
  @override
  String get history => 'История';
  @override
  String get logs => 'Логи';
  @override
  String get settings => 'Настройки';

  // Авторизация
  @override
  String get welcome => 'Добро пожаловать';
  @override
  String get login => 'Войти';
  @override
  String get register => 'Регистрация';
  @override
  String get logout => 'Выйти';
  @override
  String get email => 'Email';
  @override
  String get password => 'Пароль';
  @override
  String get name => 'Имя';
  @override
  String get confirmPassword => 'Подтвердите пароль';
  @override
  String get forgotPassword => 'Забыли пароль?';
  @override
  String get createAccount => 'Создать аккаунт';
  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт?';
  @override
  String get dontHaveAccount => 'Нет аккаунта?';
  @override
  String get enterEmail => 'Введите email';
  @override
  String get enterPassword => 'Введите пароль';
  @override
  String get enterName => 'Введите имя';
  @override
  String get enterValidEmail => 'Введите корректный email';
  @override
  String get passwordTooShort => 'Пароль слишком короткий';
  @override
  String get passwordsDontMatch => 'Пароли не совпадают';
  @override
  String get nameTooShort => 'Имя слишком короткое';
  @override
  String get loginSuccess => 'Вход выполнен успешно';
  @override
  String get registerSuccess => 'Регистрация успешна';
  @override
  String get logoutSuccess => 'Выход выполнен';
  @override
  String get invalidCredentials => 'Неверный email или пароль';
  @override
  String get userAlreadyExists => 'Пользователь уже существует';
  @override
  String get userNotFound => 'Пользователь не найден';
  @override
  String get weakPassword => 'Слабый пароль';
  @override
  String get emailInUse => 'Email уже используется';
  @override
  String get networkError => 'Ошибка сети';
  @override
  String get unknownError => 'Неизвестная ошибка';
  @override
  String get passwordResetSent => 'Новый пароль отправлен на email';
  @override
  String get passwordResetError => 'Ошибка восстановления пароля';

  // Поимки
  @override
  String get fishOn => 'Fish ON!';
  @override
  String get doubleFish => 'Double!';
  @override
  String get tripleFish => 'Triple!';
  @override
  String get addCatch => 'Добавить поимку';
  @override
  String get catchType => 'Тип поимки';
  @override
  String get location => 'Местоположение';
  @override
  String get coordinates => 'Координаты';
  @override
  String get accuracy => 'Точность';
  @override
  String get timestamp => 'Время';
  @override
  String get fisherman => 'Рыбак';
  @override
  String get catchAdded => 'Поимка добавлена';
  @override
  String get catchError => 'Ошибка добавления поимки';
  @override
  String get noCatches => 'Нет поимок';
  @override
  String get recentCatches => 'Последние поимки';
  @override
  String get allCatches => 'Все поимки';
  @override
  String get myCatches => 'Только мои';
  @override
  String get mine => 'Моя';
  @override
  String get syncCatches => 'Синхронизация поимок';
  @override
  String get syncSuccess => 'Синхронизация завершена';
  @override
  String get syncError => 'Ошибка синхронизации';
  @override
  String get sendingToTelegram => 'Отправка в Telegram...';
  @override
  String get sentToTelegram => 'Отправлено в Telegram';
  @override
  String get telegramError => 'Ошибка отправки в Telegram';
  @override
  String get sendingToServer => 'Отправка на сервер...';
  @override
  String get sentToServer => 'Отправлено на сервер';
  @override
  String get serverError => 'Ошибка сервера';

  // Карта
  @override
  String get mapView => 'Вид карты';
  @override
  String get satellite => 'Спутник';
  @override
  String get terrain => 'Рельеф';
  @override
  String get hybrid => 'Гибрид';
  @override
  String get myLocation => 'Моё местоположение';
  @override
  String get centerMap => 'Центрировать карту';
  @override
  String get zoomIn => 'Приблизить';
  @override
  String get zoomOut => 'Отдалить';
  @override
  String get compass => 'Компас';
  @override
  String get bearing => 'Направление';
  @override
  String get distance => 'Расстояние';
  @override
  String get showCatches => 'Показать поимки';
  @override
  String get hideCatches => 'Скрыть поимки';

  // Настройки
  @override
  String get generalSettings => 'Основные настройки';
  @override
  String get user => 'Пользователь';
  @override
  String get userName => 'Имя пользователя';
  @override
  String get language => 'Язык';
  @override
  String get notifications => 'Уведомления';
  @override
  String get sync => 'Синхронизация';
  @override
  String get about => 'О приложении';
  @override
  String get online => 'Онлайн';
  @override
  String get syncActive => 'Синхронизация активна';
  @override
  String get total => 'Всего';
  @override
  String get sent => 'Отправлено';
  @override
  String get pending => 'Ожидает';
  @override
  String get authorizedAs => 'Авторизован как';
  @override
  String get version => 'Версия';
  @override
  String get developer => 'Разработчик';
  @override
  String get contact => 'Контакты';
  @override
  String get privacy => 'Конфиденциальность';
  @override
  String get terms => 'Условия использования';
  @override
  String get licenses => 'Лицензии';
  @override
  String get clearData => 'Очистить данные';
  @override
  String get clearDataConfirm => 'Вы уверены, что хотите очистить все данные?';
  @override
  String get exportData => 'Экспорт данных';
  @override
  String get importData => 'Импорт данных';
  @override
  String get backup => 'Резервная копия';
  @override
  String get restore => 'Восстановить';
  @override
  String get theme => 'Тема';
  @override
  String get lightTheme => 'Светлая';
  @override
  String get darkTheme => 'Тёмная';
  @override
  String get systemTheme => 'Системная';
  @override
  String get autoSync => 'Автосинхронизация';
  @override
  String get syncInterval => 'Интервал синхронизации';
  @override
  String get offlineMode => 'Офлайн режим';
  @override
  String get enableNotifications => 'Включить уведомления';
  @override
  String get soundEnabled => 'Звук включён';
  @override
  String get vibrationEnabled => 'Вибрация включена';

  // Геолокация
  @override
  String get locationPermission => 'Разрешение на геолокацию';
  @override
  String get locationPermissionDenied => 'Доступ к геолокации запрещён';
  @override
  String get locationPermissionRequired => 'Требуется разрешение на геолокацию';
  @override
  String get locationServiceDisabled => 'Службы геолокации отключены';
  @override
  String get gettingLocation => 'Получение координат...';
  @override
  String get locationError => 'Ошибка получения координат';
  @override
  String get locationAccuracy => 'Точность геолокации';
  @override
  String get highAccuracy => 'Высокая точность';
  @override
  String get mediumAccuracy => 'Средняя точность';
  @override
  String get lowAccuracy => 'Низкая точность';
  @override
  String get gpsSignal => 'GPS сигнал';
  @override
  String get noGpsSignal => 'Нет GPS сигнала';
  @override
  String get waitingForGps => 'Ожидание GPS...';

  // Логи
  @override
  String get viewLogs => 'Просмотр логов';
  @override
  String get clearLogs => 'Очистить логи';
  @override
  String get exportLogs => 'Экспорт логов';
  @override
  String get logLevel => 'Уровень логирования';
  @override
  String get logInfo => 'Информация';
  @override
  String get logWarning => 'Предупреждения';
  @override
  String get logError => 'Ошибки';
  @override
  String get noLogs => 'Нет логов';
  @override
  String get logsCleared => 'Логи очищены';
  @override
  String get logsExported => 'Логи экспортированы';

  // История
  @override
  String get catchHistory => 'История поимок';
  @override
  String get filterBy => 'Фильтр по';
  @override
  String get filterByType => 'По типу';
  @override
  String get filterByDate => 'По дате';
  @override
  String get filterByLocation => 'По местоположению';
  @override
  String get sortBy => 'Сортировка по';
  @override
  String get sortByDate => 'По дате';
  @override
  String get sortByType => 'По типу';
  @override
  String get sortByDistance => 'По расстоянию';
  @override
  String get ascending => 'По возрастанию';
  @override
  String get descending => 'По убыванию';
  @override
  String get today => 'Сегодня';
  @override
  String get yesterday => 'Вчера';
  @override
  String get thisWeek => 'На этой неделе';
  @override
  String get thisMonth => 'В этом месяце';
  @override
  String get allTime => 'За всё время';

  // Статистика
  @override
  String get statistics => 'Статистика';
  @override
  String get totalCatches => 'Всего поимок';
  @override
  String get fishOnCount => 'Fish ON';
  @override
  String get doubleCount => 'Double';
  @override
  String get tripleCount => 'Triple';
  @override
  String get averagePerDay => 'В среднем за день';
  @override
  String get bestDay => 'Лучший день';
  @override
  String get bestLocation => 'Лучшее место';
  @override
  String get longestStreak => 'Самая длинная серия';
  @override
  String get currentStreak => 'Текущая серия';

  // Ошибки и сообщения
  @override
  String get connectionError => 'Ошибка подключения';
  @override
  String get serverUnavailable => 'Сервер недоступен';
  @override
  String get timeoutError => 'Превышено время ожидания';
  @override
  String get dataCorrupted => 'Данные повреждены';
  @override
  String get insufficientStorage => 'Недостаточно места';
  @override
  String get permissionDenied => 'Доступ запрещён';
  @override
  String get featureNotAvailable => 'Функция недоступна';
  @override
  String get updateRequired => 'Требуется обновление';
  @override
  String get maintenanceMode => 'Режим обслуживания';
  @override
  String get rateLimitExceeded => 'Превышен лимит запросов';

  // Диалоги
  @override
  String get confirmDelete => 'Подтвердите удаление';
  @override
  String get confirmClear => 'Подтвердите очистку';
  @override
  String get confirmLogout => 'Подтвердите выход';
  @override
  String get confirmExit => 'Подтвердите выход из приложения';
  @override
  String get unsavedChanges => 'Несохранённые изменения';
  @override
  String get discardChanges => 'Отменить изменения';
  @override
  String get saveChanges => 'Сохранить изменения';

  // Время
  @override
  String get now => 'Сейчас';
  @override
  String get minutesAgo => 'минут назад';
  @override
  String get hoursAgo => 'часов назад';
  @override
  String get daysAgo => 'дней назад';
  @override
  String get weeksAgo => 'недель назад';
  @override
  String get monthsAgo => 'месяцев назад';
  @override
  String get yearsAgo => 'лет назад';

  // Единицы измерения
  @override
  String get meters => 'м';
  @override
  String get kilometers => 'км';
  @override
  String get feet => 'фт';
  @override
  String get miles => 'мили';
  @override
  String get degrees => '°';
  @override
  String get seconds => 'сек';
  @override
  String get minutes => 'мин';
  @override
  String get hours => 'ч';
  @override
  String get days => 'дн';

  // Направления
  @override
  String get north => 'С';
  @override
  String get south => 'Ю';
  @override
  String get east => 'В';
  @override
  String get west => 'З';
  @override
  String get northeast => 'СВ';
  @override
  String get northwest => 'СЗ';
  @override
  String get southeast => 'ЮВ';
  @override
  String get southwest => 'ЮЗ';

  // Дополнительные строки для логов
  @override
  String get clearAllLogs => 'Очистить все';
  
  @override
  String get clearLogsTitle => 'Очистить логи';
  
  @override
  String get clearLogsConfirm => 'Вы уверены, что хотите удалить все логи?';
  
  @override
  String get filterByLevel => 'Фильтр по уровню:';
  
  @override
  String get all => 'Все';
  
  @override
  String get infoLogs => 'Инфо';
  
  @override
  String get warningLogs => 'Предупреждения';
  
  @override
  String get errorLogs => 'Ошибки';
  
  @override
  String get loadingLogsError => 'Ошибка загрузки логов';
  
  @override
  String get clearingError => 'Ошибка очистки';

  // Дополнительные строки для полной локализации
  @override
  String get retryInterval => 'Интервал повторных попыток';
  
  @override
  String get minutesShort => 'мин';
  
  @override
  String get account => 'Аккаунт';
  
  @override
  String get pendingSend => 'Ожидает отправки';
  
  @override
  String get catchMap => 'Карта поимок';
  
  @override
  String get catches => 'поимок';

  @override
  String get cooldownMessage => 'сек минимальный кулдаун';

  @override
  String get dailyLimitReached => 'Дневной лимит достигнут';

  @override
  String get catchSaved => 'Поимка сохранена!';

  @override
  String get locationPermissionNeeded => 'Нужно разрешение на геолокацию';

  @override
  String get status => 'Статус';

  @override
  String get locationPermissionDescription => 'Для создания поимки необходимо разрешение на использование геолокации.';

  @override
  String get pleaseGrantPermission => 'Пожалуйста, предоставьте разрешение в настройках.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get permissionGranted => 'Разрешение получено!';

  @override
  String get nameCannotBeEmpty => 'Имя не может быть пустым';

  @override
  String get nameCannotBeLonger => 'Имя не может быть длиннее';

  @override
  String get symbols => 'символов';

  @override
  String get nameNotChanged => 'Имя не изменилось';

  @override
  String get nameSaved => 'Имя сохранено';

  @override
  String get intervalSaved => 'Интервал сохранен';

  @override
  String get minute => 'минута';

  @override
  String get minutes2to4 => 'минуты';

  @override
  String get minutes5plus => 'минут';

  @override
  String get clearAllData => 'Очистить все данные';

  @override
  String get clearAllDataConfirmation => 'Это удалит все поимки и логи. Действие нельзя отменить. Продолжить?';

  @override
  String get dataCleared => 'Данные очищены';

  @override
  String get offline => 'Офлайн';

  @override
  String get noInternetConnection => 'Нет подключения к интернету';

  @override
  String get appDescription => 'Приложение для сообщества рыбаков Кипра. Позволяет быстро делиться информацией о поимках тунца.';

  @override
  String get developedForSea => 'Разработано с учетом работы в море при отсутствии стабильного интернета.';

  @override
  String get languageLabel => 'Язык / Language';

  @override
  String get chooseLanguage => 'Выберите язык / Choose Language';

  @override
  String get cancelSlashCancel => 'Отмена / Cancel';

  @override
  String get languageChanged => 'Язык изменен / Language changed';

  @override
  String get signOutTitle => 'Выйти из аккаунта';

  @override
  String get signOutConfirmation => 'Вы уверены, что хотите выйти из аккаунта? Все несохраненные данные будут потеряны.';

  @override
  String get signOut => 'Выйти';
}
