import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../models/catch_record.dart';
import 'log_service.dart';

/// Сервис для создания и экспорта GPX файлов
class GpxService {
  static final GpxService _instance = GpxService._internal();
  factory GpxService() => _instance;
  GpxService._internal();

  final LogService _log = LogService();

  /// Создать и открыть GPX файл для поимки
  Future<void> exportCatchToGpx(BuildContext context, CatchRecord catch_) async {
    try {
      await _log.info('Создание GPX файла для поимки: ${catch_.id}');
      
      // Генерируем содержимое GPX
      final gpxContent = _generateGpxContent(catch_);
      
      // Создаем файл
      final file = await _createGpxFile(catch_, gpxContent);
      
      // Открываем файл стандартными средствами
      final result = await OpenFile.open(file.path);
      
      if (result.type == ResultType.done) {
        await _log.info('GPX файл успешно открыт: ${file.path}');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPX файл создан: ${file.path.split('/').last}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Открыть',
                textColor: Colors.white,
                onPressed: () => OpenFile.open(file.path),
              ),
            ),
          );
        }
      } else {
        throw Exception('Не удалось открыть файл: ${result.message}');
      }
    } catch (e) {
      await _log.error('Ошибка создания GPX файла', e);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания GPX: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Генерировать содержимое GPX файла в формате 1.1
  String _generateGpxContent(CatchRecord catch_) {
    final timestampFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    final timestamp = timestampFormatter.format(catch_.timestamp.toUtc());
    
    // Название точки: имя пользователя + дата + время поимки
    final dateFormatter = DateFormat('dd.MM.yy');
    final timeFormatter = DateFormat('HH:mm');
    final pointName = '${catch_.userName} - ${dateFormatter.format(catch_.timestamp)} - ${timeFormatter.format(catch_.timestamp)}';
    
    // Описание с дополнительной информацией
    final description = '''
Поимка: ${catch_.catchTypeDisplay}
Рыбак: ${catch_.userName}
Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(catch_.timestamp)}
Координаты: ${catch_.latitude.toStringAsFixed(6)}, ${catch_.longitude.toStringAsFixed(6)}
Статус: ${catch_.isSentToTelegram ? 'Отправлено' : 'Ожидает отправки'}
'''.trim();

    return '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="CyFishON" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
  <metadata>
    <name>CyFishON - Поимка тунца</name>
    <desc>Экспорт координат поимки из приложения CyFishON</desc>
    <author>
      <name>CyFishON App</name>
    </author>
    <time>$timestamp</time>
  </metadata>
  <wpt lat="${catch_.latitude.toStringAsFixed(6)}" lon="${catch_.longitude.toStringAsFixed(6)}">
    <time>$timestamp</time>
    <name>$pointName</name>
    <desc>$description</desc>
    <type>fishing</type>
    <sym>Fishing Hot Spot Facility</sym>
  </wpt>
</gpx>''';
  }

  /// Создать GPX файл в файловой системе
  Future<File> _createGpxFile(CatchRecord catch_, String content) async {
    // Получаем директорию для сохранения
    final directory = await getApplicationDocumentsDirectory();
    
    // Создаем поддиректорию для GPX файлов
    final gpxDir = Directory('${directory.path}/gpx');
    if (!await gpxDir.exists()) {
      await gpxDir.create(recursive: true);
    }
    
    // Генерируем имя файла
    final dateFormatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final dateStr = dateFormatter.format(catch_.timestamp);
    final fileName = 'CyFishON_${catch_.userName}_${catch_.catchType}_$dateStr.gpx';
    
    // Создаем файл
    final file = File('${gpxDir.path}/$fileName');
    await file.writeAsString(content, encoding: utf8);
    
    await _log.info('GPX файл создан: ${file.path}');
    return file;
  }

  /// Экспортировать несколько поимок в один GPX файл
  Future<void> exportMultipleCatchesToGpx(
    BuildContext context, 
    List<CatchRecord> catches,
  ) async {
    if (catches.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет поимок для экспорта'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await _log.info('Создание GPX файла для ${catches.length} поимок');
      
      // Генерируем содержимое GPX для нескольких точек
      final gpxContent = _generateMultipleGpxContent(catches);
      
      // Создаем файл
      final file = await _createMultipleGpxFile(catches, gpxContent);
      
      // Открываем файл
      final result = await OpenFile.open(file.path);
      
      if (result.type == ResultType.done) {
        await _log.info('GPX файл с ${catches.length} точками успешно открыт');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPX файл создан с ${catches.length} точками'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Открыть',
                textColor: Colors.white,
                onPressed: () => OpenFile.open(file.path),
              ),
            ),
          );
        }
      } else {
        throw Exception('Не удалось открыть файл: ${result.message}');
      }
    } catch (e) {
      await _log.error('Ошибка создания GPX файла для нескольких поимок', e);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания GPX: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Генерировать GPX для нескольких поимок
  String _generateMultipleGpxContent(List<CatchRecord> catches) {
    final dateFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    final now = dateFormatter.format(DateTime.now().toUtc());
    
    final waypoints = catches.map((catch_) {
      final timestamp = dateFormatter.format(catch_.timestamp.toUtc());
      // Название точки: имя пользователя + дата + время поимки
      final pointDateFormatter = DateFormat('dd.MM.yy');
      final pointTimeFormatter = DateFormat('HH:mm');
      final pointName = '${catch_.userName} - ${pointDateFormatter.format(catch_.timestamp)} - ${pointTimeFormatter.format(catch_.timestamp)}';
      
      final description = '''
Поимка: ${catch_.catchTypeDisplay}
Рыбак: ${catch_.userName}
Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(catch_.timestamp)}
Координаты: ${catch_.latitude.toStringAsFixed(6)}, ${catch_.longitude.toStringAsFixed(6)}
Статус: ${catch_.isSentToTelegram ? 'Отправлено' : 'Ожидает отправки'}
'''.trim();

      return '''  <wpt lat="${catch_.latitude.toStringAsFixed(6)}" lon="${catch_.longitude.toStringAsFixed(6)}">
    <time>$timestamp</time>
    <name>$pointName</name>
    <desc>$description</desc>
    <type>fishing</type>
    <sym>Fishing Hot Spot Facility</sym>
  </wpt>''';
    }).join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="CyFishON" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
  <metadata>
    <name>CyFishON - Поимки тунца (${catches.length} точек)</name>
    <desc>Экспорт координат поимок из приложения CyFishON</desc>
    <author>
      <name>CyFishON App</name>
    </author>
    <time>$now</time>
  </metadata>
$waypoints
</gpx>''';
  }

  /// Создать GPX файл для нескольких поимок
  Future<File> _createMultipleGpxFile(List<CatchRecord> catches, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    
    final gpxDir = Directory('${directory.path}/gpx');
    if (!await gpxDir.exists()) {
      await gpxDir.create(recursive: true);
    }
    
    final dateFormatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final dateStr = dateFormatter.format(DateTime.now());
    final fileName = 'CyFishON_${catches.length}_catches_$dateStr.gpx';
    
    final file = File('${gpxDir.path}/$fileName');
    await file.writeAsString(content, encoding: utf8);
    
    await _log.info('GPX файл создан для ${catches.length} поимок: ${file.path}');
    return file;
  }
}
