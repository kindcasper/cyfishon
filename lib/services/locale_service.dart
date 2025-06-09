import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления локализацией
class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  static const String _keyLanguage = 'selected_language';
  
  Locale _currentLocale = const Locale('ru'); // По умолчанию русский
  
  Locale get currentLocale => _currentLocale;
  
  /// Поддерживаемые языки
  static const List<Locale> supportedLocales = [
    Locale('ru'), // Русский
    Locale('en'), // Английский
  ];
  
  /// Названия языков для отображения
  static const Map<String, String> languageNames = {
    'ru': 'Русский',
    'en': 'English',
  };
  
  /// Инициализация сервиса
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_keyLanguage);
    
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
    } else {
      // Определяем язык системы
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (supportedLocales.any((locale) => locale.languageCode == systemLocale.languageCode)) {
        _currentLocale = Locale(systemLocale.languageCode);
      }
    }
    
    notifyListeners();
  }
  
  /// Изменить язык
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, locale.languageCode);
    
    notifyListeners();
  }
  
  /// Получить название языка
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
  
  /// Проверить, поддерживается ли язык
  bool isSupported(Locale locale) {
    return supportedLocales.any((supported) => supported.languageCode == locale.languageCode);
  }
}
