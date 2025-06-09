import 'package:flutter/material.dart';

/// Класс локализации приложения
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Общие
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get close;
  String get back;
  String get next;
  String get loading;
  String get error;
  String get success;
  String get warning;
  String get info;
  String get retry;
  String get yes;
  String get no;

  // Навигация
  String get home;
  String get map;
  String get history;
  String get logs;
  String get settings;

  // Авторизация
  String get welcome;
  String get login;
  String get register;
  String get logout;
  String get email;
  String get password;
  String get name;
  String get confirmPassword;
  String get forgotPassword;
  String get createAccount;
  String get alreadyHaveAccount;
  String get dontHaveAccount;
  String get enterEmail;
  String get enterPassword;
  String get enterName;
  String get enterValidEmail;
  String get passwordTooShort;
  String get passwordsDontMatch;
  String get nameTooShort;
  String get loginSuccess;
  String get registerSuccess;
  String get logoutSuccess;
  String get invalidCredentials;
  String get userAlreadyExists;
  String get userNotFound;
  String get weakPassword;
  String get emailInUse;
  String get networkError;
  String get unknownError;
  String get passwordResetSent;
  String get passwordResetError;

  // Поимки
  String get fishOn;
  String get doubleFish;
  String get tripleFish;
  String get addCatch;
  String get catchType;
  String get location;
  String get coordinates;
  String get accuracy;
  String get timestamp;
  String get fisherman;
  String get catchAdded;
  String get catchError;
  String get noCatches;
  String get recentCatches;
  String get allCatches;
  String get myCatches;
  String get mine;
  String get syncCatches;
  String get syncSuccess;
  String get syncError;
  String get sendingToTelegram;
  String get sentToTelegram;
  String get telegramError;
  String get sendingToServer;
  String get sentToServer;
  String get serverError;

  // Карта
  String get mapView;
  String get satellite;
  String get terrain;
  String get hybrid;
  String get myLocation;
  String get centerMap;
  String get zoomIn;
  String get zoomOut;
  String get compass;
  String get bearing;
  String get distance;
  String get showCatches;
  String get hideCatches;

  // Настройки
  String get generalSettings;
  String get user;
  String get userName;
  String get language;
  String get notifications;
  String get sync;
  String get about;
  String get online;
  String get syncActive;
  String get total;
  String get sent;
  String get pending;
  String get authorizedAs;
  String get version;
  String get developer;
  String get contact;
  String get privacy;
  String get terms;
  String get licenses;
  String get clearData;
  String get clearDataConfirm;
  String get dataCleared;
  String get exportData;
  String get importData;
  String get backup;
  String get restore;
  String get theme;
  String get lightTheme;
  String get darkTheme;
  String get systemTheme;
  String get autoSync;
  String get syncInterval;
  String get offlineMode;
  String get enableNotifications;
  String get soundEnabled;
  String get vibrationEnabled;

  // Геолокация
  String get locationPermission;
  String get locationPermissionDenied;
  String get locationPermissionRequired;
  String get locationServiceDisabled;
  String get gettingLocation;
  String get locationError;
  String get locationAccuracy;
  String get highAccuracy;
  String get mediumAccuracy;
  String get lowAccuracy;
  String get gpsSignal;
  String get noGpsSignal;
  String get waitingForGps;

  // Логи
  String get viewLogs;
  String get clearLogs;
  String get exportLogs;
  String get logLevel;
  String get logInfo;
  String get logWarning;
  String get logError;
  String get noLogs;
  String get logsCleared;
  String get logsExported;

  // История
  String get catchHistory;
  String get filterBy;
  String get filterByType;
  String get filterByDate;
  String get filterByLocation;
  String get sortBy;
  String get sortByDate;
  String get sortByType;
  String get sortByDistance;
  String get ascending;
  String get descending;
  String get today;
  String get yesterday;
  String get thisWeek;
  String get thisMonth;
  String get allTime;

  // Статистика
  String get statistics;
  String get totalCatches;
  String get fishOnCount;
  String get doubleCount;
  String get tripleCount;
  String get averagePerDay;
  String get bestDay;
  String get bestLocation;
  String get longestStreak;
  String get currentStreak;

  // Ошибки и сообщения
  String get connectionError;
  String get serverUnavailable;
  String get timeoutError;
  String get dataCorrupted;
  String get insufficientStorage;
  String get permissionDenied;
  String get featureNotAvailable;
  String get updateRequired;
  String get maintenanceMode;
  String get rateLimitExceeded;

  // Диалоги
  String get confirmDelete;
  String get confirmClear;
  String get confirmLogout;
  String get confirmExit;
  String get unsavedChanges;
  String get discardChanges;
  String get saveChanges;

  // Время
  String get now;
  String get minutesAgo;
  String get hoursAgo;
  String get daysAgo;
  String get weeksAgo;
  String get monthsAgo;
  String get yearsAgo;

  // Единицы измерения
  String get meters;
  String get kilometers;
  String get feet;
  String get miles;
  String get degrees;
  String get seconds;
  String get minutes;
  String get hours;
  String get days;

  // Направления
  String get north;
  String get south;
  String get east;
  String get west;
  String get northeast;
  String get northwest;
  String get southeast;
  String get southwest;
}
