import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_en.dart';

/// Делегат локализации приложения
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ru', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'ru':
      default:
        return AppLocalizationsRu();
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
