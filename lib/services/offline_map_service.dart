import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'log_service.dart';

/// Сервис для управления офлайн картами
class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  final LogService _log = LogService();
  
  // Путь к папке с тайлами карты
  String? _tilesDirectory;
  
  // Границы предзагруженной карты Кипра
  static const double _minLat = 34.5;
  static const double _maxLat = 35.7;
  static const double _minLng = 32.2;
  static const double _maxLng = 34.6;
  static const int _minZoom = 8;
  static const int _maxZoom = 16;

  /// Инициализация сервиса офлайн карт
  Future<void> initialize() async {
    try {
      await _log.info('Инициализация сервиса офлайн карт');
      
      // Получаем директорию для хранения тайлов
      final appDir = await getApplicationDocumentsDirectory();
      _tilesDirectory = path.join(appDir.path, 'offline_maps');
      
      // Создаем директорию если её нет
      final tilesDir = Directory(_tilesDirectory!);
      if (!await tilesDir.exists()) {
        await tilesDir.create(recursive: true);
      }
      
      // Проверяем наличие предзагруженных тайлов
      await _checkAndExtractPreloadedTiles();
      
      await _log.info('Сервис офлайн карт инициализирован');
    } catch (e) {
      await _log.error('Ошибка инициализации сервиса офлайн карт', e);
    }
  }

  /// Проверка и извлечение предзагруженных тайлов из assets
  Future<void> _checkAndExtractPreloadedTiles() async {
    try {
      // Проверяем, есть ли уже извлеченные тайлы
      final versionFile = File(path.join(_tilesDirectory!, 'version.txt'));
      const currentVersion = '1.0.2';
      
      bool needsExtraction = true;
      if (await versionFile.exists()) {
        final existingVersion = await versionFile.readAsString();
        if (existingVersion.trim() == currentVersion) {
          needsExtraction = false;
          await _log.info('Офлайн карты уже актуальны (версия $currentVersion)');
        }
      }
      
      if (needsExtraction) {
        await _log.info('Извлечение предзагруженных тайлов карты...');
        await _extractTilesFromAssets();
        await versionFile.writeAsString(currentVersion);
        await _log.info('Предзагруженные тайлы карты извлечены');
      }
    } catch (e) {
      await _log.error('Ошибка при извлечении предзагруженных тайлов', e);
    }
  }

  /// Извлечение тайлов из assets
  Future<void> _extractTilesFromAssets() async {
    try {
      int extractedCount = 0;
      
      // Извлекаем тайлы для зума 10 (основные тайлы Кипра)
      final tilePaths = [
        'assets/tiles/10/603/403.png',
        'assets/tiles/10/603/404.png',
        'assets/tiles/10/603/405.png',
        'assets/tiles/10/603/406.png',
        'assets/tiles/10/603/407.png',
        'assets/tiles/10/604/403.png',
        'assets/tiles/10/604/404.png',
        'assets/tiles/10/604/405.png',
        'assets/tiles/10/604/406.png',
        'assets/tiles/10/604/407.png',
        'assets/tiles/10/605/403.png',
        'assets/tiles/10/605/404.png',
        'assets/tiles/10/605/405.png',
        'assets/tiles/10/605/406.png',
      ];
      
      for (final assetPath in tilePaths) {
        try {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          
          // Определяем путь для сохранения
          final relativePath = assetPath.replaceFirst('assets/tiles/', '');
          final targetPath = path.join(_tilesDirectory!, relativePath);
          
          // Создаем директории если нужно
          final targetDir = Directory(path.dirname(targetPath));
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
          
          // Сохраняем файл
          final file = File(targetPath);
          await file.writeAsBytes(bytes);
          extractedCount++;
          
          await _log.info('Извлечен тайл: $relativePath');
        } catch (e) {
          await _log.warning('Не удалось извлечь тайл: $assetPath');
        }
      }
      
      await _log.info('Извлечено $extractedCount тайлов из assets');
    } catch (e) {
      await _log.error('Ошибка извлечения тайлов из assets', e);
    }
  }

  /// Получить URL для офлайн тайла
  String? getOfflineTileUrl(int x, int y, int z) {
    if (_tilesDirectory == null) return null;
    
    final tilePath = path.join(_tilesDirectory!, z.toString(), x.toString(), '$y.png');
    final file = File(tilePath);
    
    if (file.existsSync()) {
      return 'file://$tilePath';
    }
    
    return null;
  }

  /// Проверить, доступен ли тайл офлайн
  bool isTileAvailableOffline(int x, int y, int z) {
    if (_tilesDirectory == null) return false;
    
    final tilePath = path.join(_tilesDirectory!, z.toString(), x.toString(), '$y.png');
    return File(tilePath).existsSync();
  }

  /// Получить статистику офлайн карт
  Future<Map<String, dynamic>> getOfflineMapStats() async {
    if (_tilesDirectory == null) {
      return {'totalTiles': 0, 'totalSize': 0, 'coverage': 'Не инициализировано'};
    }

    try {
      int totalTiles = 0;
      int totalSize = 0;
      
      final tilesDir = Directory(_tilesDirectory!);
      if (await tilesDir.exists()) {
        await for (final entity in tilesDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.png')) {
            totalTiles++;
            final stat = await entity.stat();
            totalSize += stat.size;
          }
        }
      }
      
      final sizeInMB = (totalSize / (1024 * 1024)).toStringAsFixed(1);
      
      return {
        'totalTiles': totalTiles,
        'totalSize': totalSize,
        'sizeInMB': sizeInMB,
        'coverage': 'Кипр (зум $_minZoom-$_maxZoom)',
        'bounds': {
          'minLat': _minLat,
          'maxLat': _maxLat,
          'minLng': _minLng,
          'maxLng': _maxLng,
        }
      };
    } catch (e) {
      await _log.error('Ошибка получения статистики офлайн карт', e);
      return {'totalTiles': 0, 'totalSize': 0, 'coverage': 'Ошибка'};
    }
  }

  /// Очистить кэш офлайн карт
  Future<void> clearOfflineCache() async {
    try {
      if (_tilesDirectory != null) {
        final tilesDir = Directory(_tilesDirectory!);
        if (await tilesDir.exists()) {
          await tilesDir.delete(recursive: true);
          await tilesDir.create(recursive: true);
        }
      }
      await _log.info('Кэш офлайн карт очищен');
    } catch (e) {
      await _log.error('Ошибка очистки кэша офлайн карт', e);
    }
  }

  /// Проверить, находится ли точка в зоне покрытия офлайн карт
  bool isPointInOfflineCoverage(double lat, double lng) {
    return lat >= _minLat && 
           lat <= _maxLat && 
           lng >= _minLng && 
           lng <= _maxLng;
  }

  /// Получить путь к директории тайлов
  String? get tilesDirectory => _tilesDirectory;
}
