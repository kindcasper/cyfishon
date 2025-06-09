import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'log_service.dart';

/// Сервис для работы с компасом
class CompassService {
  static final CompassService _instance = CompassService._internal();
  factory CompassService() => _instance;
  CompassService._internal();

  final LogService _log = LogService();
  
  StreamSubscription<CompassEvent>? _compassSubscription;
  final StreamController<double> _headingController = StreamController<double>.broadcast();
  
  double _currentHeading = 0.0;
  bool _isListening = false;

  /// Поток с текущим направлением компаса (в градусах)
  Stream<double> get headingStream => _headingController.stream;

  /// Текущее направление компаса
  double get currentHeading => _currentHeading;

  /// Проверить доступность компаса
  Future<bool> isCompassAvailable() async {
    try {
      final events = FlutterCompass.events;
      if (events == null) {
        await _log.warning('Компас недоступен на этом устройстве');
        return false;
      }
      return true;
    } catch (e) {
      await _log.error('Ошибка проверки доступности компаса', e);
      return false;
    }
  }

  /// Начать прослушивание компаса
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      final isAvailable = await isCompassAvailable();
      if (!isAvailable) return;

      await _log.info('Запуск сервиса компаса');

      _compassSubscription = FlutterCompass.events!.listen(
        (CompassEvent event) {
          if (event.heading != null) {
            _currentHeading = event.heading!;
            _headingController.add(_currentHeading);
          }
        },
        onError: (error) async {
          await _log.error('Ошибка компаса', error);
        },
      );

      _isListening = true;
      await _log.info('Сервис компаса запущен');
    } catch (e) {
      await _log.error('Ошибка запуска сервиса компаса', e);
    }
  }

  /// Остановить прослушивание компаса
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _compassSubscription?.cancel();
      _compassSubscription = null;
      _isListening = false;
      await _log.info('Сервис компаса остановлен');
    } catch (e) {
      await _log.error('Ошибка остановки сервиса компаса', e);
    }
  }

  /// Преобразовать градусы в радианы
  double degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Преобразовать радианы в градусы
  double radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  /// Получить направление как текст (С, СВ, В, ЮВ, Ю, ЮЗ, З, СЗ)
  String getDirectionText(double heading) {
    const directions = [
      'С', 'ССВ', 'СВ', 'ВСВ',
      'В', 'ВЮВ', 'ЮВ', 'ЮЮВ',
      'Ю', 'ЮЮЗ', 'ЮЗ', 'ЗЮЗ',
      'З', 'ЗСЗ', 'СЗ', 'ССЗ'
    ];
    
    final index = ((heading + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Освободить ресурсы
  void dispose() {
    stopListening();
    _headingController.close();
  }
}
