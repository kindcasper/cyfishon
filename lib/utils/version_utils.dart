import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Утилиты для работы с версией приложения
class VersionUtils {
  static String? _cachedVersion;

  /// Получить версию приложения из pubspec.yaml
  static Future<String> getAppVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      // Читаем pubspec.yaml
      final pubspecString = await rootBundle.loadString('pubspec.yaml');
      final pubspec = loadYaml(pubspecString);
      
      // Извлекаем версию
      final version = pubspec['version'] as String?;
      if (version != null) {
        // Убираем build number если есть (например, 1.0.0+1 -> 1.0.0)
        _cachedVersion = version.split('+').first;
        return _cachedVersion!;
      }
    } catch (e) {
      // Если не удалось прочитать, возвращаем версию по умолчанию
      print('Ошибка чтения версии из pubspec.yaml: $e');
    }

    // Fallback версия
    _cachedVersion = '1.0.0';
    return _cachedVersion!;
  }

  /// Очистить кеш версии (для принудительного обновления)
  static void clearCache() {
    _cachedVersion = null;
  }
}
