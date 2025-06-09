import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import 'log_service.dart';

/// Сервис для работы с GPS координатами
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final LogService _log = LogService();

  /// Проверить и запросить разрешения на геолокацию
  Future<bool> checkPermissions() async {
    // Проверяем статус разрешения
    final status = await Permission.location.status;
    
    if (status.isDenied) {
      // Запрашиваем разрешение
      final result = await Permission.location.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }

  /// Проверить, включена ли геолокация
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Получить текущие координаты с проверкой точности
  Future<Position?> getCurrentLocation() async {
    try {
      // Проверяем разрешения
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        await _log.logLocationError('Нет разрешения на использование геолокации');
        return null;
      }

      // Проверяем, включена ли геолокация
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _log.logLocationError('Геолокация отключена');
        return null;
      }

      // Пытаемся получить координаты несколько раз для лучшей точности
      Position? bestPosition;
      
      for (int attempt = 0; attempt < AppConfig.maxLocationAttempts; attempt++) {
        await _log.info('Попытка получения координат', 'Попытка ${attempt + 1}');
        
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: AppConfig.requestTimeoutSeconds),
        );
        
        // Если точность достаточная, используем эти координаты
        if (position.accuracy <= AppConfig.requiredAccuracy) {
          await _log.logLocationReceived(
            position.latitude,
            position.longitude,
            position.accuracy,
          );
          return position;
        }
        
        // Сохраняем лучшую позицию
        if (bestPosition == null || position.accuracy < bestPosition.accuracy) {
          bestPosition = position;
        }
        
        // Небольшая задержка между попытками
        if (attempt < AppConfig.maxLocationAttempts - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      
      // Возвращаем лучшую полученную позицию
      if (bestPosition != null) {
        await _log.warning(
          'Координаты получены с низкой точностью',
          'Точность: ${bestPosition.accuracy}м',
        );
        await _log.logLocationReceived(
          bestPosition.latitude,
          bestPosition.longitude,
          bestPosition.accuracy,
        );
      }
      
      return bestPosition;
    } catch (e) {
      await _log.logLocationError(e.toString());
      return null;
    }
  }

  /// Форматировать координату в градусы°минуты.тысячные′
  String formatCoordinate(double coordinate, bool isLatitude) {
    final isNegative = coordinate < 0;
    final absCoordinate = coordinate.abs();
    
    // Получаем градусы
    final degrees = absCoordinate.floor();
    
    // Получаем минуты
    final minutesDecimal = (absCoordinate - degrees) * 60;
    final minutes = minutesDecimal.floor();
    
    // Получаем тысячные доли минут
    final minutesFraction = ((minutesDecimal - minutes) * 1000).round();
    
    // Определяем направление
    String direction;
    if (isLatitude) {
      direction = isNegative ? 'S' : 'N';
    } else {
      direction = isNegative ? 'W' : 'E';
    }
    
    // Форматируем строку
    return '$degrees°${minutes.toString().padLeft(2, '0')}.${minutesFraction.toString().padLeft(3, '0')}′$direction';
  }

  /// Форматировать позицию для отображения
  Map<String, String> formatPosition(Position position) {
    return {
      'latitude': formatCoordinate(position.latitude, true),
      'longitude': formatCoordinate(position.longitude, false),
    };
  }

  /// Получить последнюю известную позицию (из кеша)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      await _log.error('Ошибка получения последней позиции', e);
      return null;
    }
  }

  /// Подписаться на обновления позиции
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // минимальное расстояние для обновления в метрах
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Рассчитать расстояние между двумя точками (в метрах)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
