import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/map_widgets.dart';
import '../services/location_service.dart';
import '../services/compass_service.dart';
import '../services/database_service.dart';
import '../services/log_service.dart';
import '../services/offline_map_service.dart';
import '../models/catch_record.dart';
import '../l10n/app_localizations.dart';

/// Экран карты с отображением всех поимок
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final CompassService _compassService = CompassService();
  final DatabaseService _databaseService = DatabaseService();
  final LogService _logService = LogService();
  
  final MapController _mapController = MapController();
  
  // Границы карты Кипра + 30 морских миль
  static final LatLngBounds _cyprusBounds = LatLngBounds(
    const LatLng(33.5, 31.5), // Юго-запад
    const LatLng(36.5, 35.5), // Северо-восток
  );
  
  // Центр Кипра для начального отображения
  static const LatLng _cyprusCenter = LatLng(35.1264, 33.4299);
  
  Position? _currentPosition;
  double _currentHeading = 0.0;
  List<CatchRecord> _catches = [];
  CatchRecord? _selectedCatch;
  
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _headingSubscription;
  
  bool _isLoading = true;
  bool _isLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    _compassService.stopListening();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _logService.info('Инициализация карты');
      
      // Загружаем поимки из базы данных
      await _loadCatches();
      
      // Запускаем сервисы
      await _startLocationService();
      await _startCompassService();
      
      setState(() {
        _isLoading = false;
      });
      
      await _logService.info('Карта инициализирована');
    } catch (e) {
      await _logService.error('Ошибка инициализации карты', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCatches() async {
    try {
      final catches = await _databaseService.getCatches();
      setState(() {
        _catches = catches;
      });
      await _logService.info('Загружено ${catches.length} поимок на карту');
    } catch (e) {
      await _logService.error('Ошибка загрузки поимок для карты', e);
    }
  }

  Future<void> _startLocationService() async {
    try {
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        await _logService.warning('Нет разрешения на геолокацию для карты');
        return;
      }

      // Получаем текущую позицию
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLocationEnabled = true;
        });
        
        // Центрируем карту на текущем местоположении
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }

      // Подписываемся на обновления позиции
      _positionSubscription = _locationService.getPositionStream().listen(
        (position) {
          setState(() {
            _currentPosition = position;
            _isLocationEnabled = true;
          });
        },
        onError: (error) async {
          await _logService.error('Ошибка получения местоположения для карты', error);
        },
      );
    } catch (e) {
      await _logService.error('Ошибка запуска сервиса геолокации для карты', e);
    }
  }

  Future<void> _startCompassService() async {
    try {
      final isAvailable = await _compassService.isCompassAvailable();
      if (!isAvailable) {
        await _logService.warning('Компас недоступен для карты');
        return;
      }

      _headingSubscription = _compassService.headingStream.listen(
        (heading) {
          setState(() {
            _currentHeading = heading;
          });
        },
      );

      await _compassService.startListening();
    } catch (e) {
      await _logService.error('Ошибка запуска сервиса компаса для карты', e);
    }
  }

  void _onCatchMarkerTap(CatchRecord catch_) async {
    await _logService.info('Клик на маркер поимки: ${catch_.userName} - ${catch_.catchTypeDisplay}');
    setState(() {
      _selectedCatch = catch_;
    });
  }

  void _onTooltipDismiss() async {
    await _logService.info('Закрытие хинта поимки');
    setState(() {
      _selectedCatch = null;
    });
  }

  void _centerOnCurrentLocation() async {
    if (_currentPosition != null) {
      await _logService.info('Центрирование карты на текущем местоположении');
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    } else {
      await _logService.warning('Попытка центрирования без доступного местоположения');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(l10n.catchMap),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLocationEnabled)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _centerOnCurrentLocation,
              tooltip: 'Центрировать на моем местоположении',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка карты...'),
                ],
              ),
            )
          : Stack(
              children: [
                // Основная карта
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _cyprusCenter,
                    initialZoom: _currentPosition != null ? 14.0 : 10.0,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                    cameraConstraint: CameraConstraint.contain(
                      bounds: _cyprusBounds,
                    ),
                  ),
                  children: [
                    // Слой карты с офлайн поддержкой
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cyfishon.app',
                      maxZoom: 18,
                      // Функция для получения офлайн тайлов
                      tileProvider: OfflineTileProvider(),
                    ),
                    
                    // Слой маркеров поимок
                    MarkerLayer(
                      markers: _catches.map((catch_) {
                        return Marker(
                          point: LatLng(catch_.latitude, catch_.longitude),
                          width: 24,
                          height: 24,
                          child: CatchMarker(
                            catchRecord: catch_,
                            onTap: () => _onCatchMarkerTap(catch_),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // Слой маркера текущего местоположения
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 30,
                            height: 30,
                            child: CurrentLocationMarker(
                              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              heading: _currentHeading,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Информационная панель
                MapInfoPanel(
                  totalCatches: _catches.length,
                  currentLocation: _isLocationEnabled ? 'GPS активен' : 'GPS отключен',
                  currentHeading: _currentHeading,
                ),
                
                // Всплывающий хинт при выборе поимки
                if (_selectedCatch != null)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.3,
                    left: MediaQuery.of(context).size.width * 0.1,
                    right: MediaQuery.of(context).size.width * 0.1,
                    child: CatchTooltip(
                      catchRecord: _selectedCatch!,
                      position: LatLng(_selectedCatch!.latitude, _selectedCatch!.longitude),
                      onDismiss: _onTooltipDismiss,
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

/// Провайдер тайлов с офлайн поддержкой
class OfflineTileProvider extends TileProvider {
  final OfflineMapService _offlineMapService = OfflineMapService();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // Сначала пытаемся получить офлайн тайл
    final offlineUrl = _offlineMapService.getOfflineTileUrl(
      coordinates.x, 
      coordinates.y, 
      coordinates.z
    );
    
    if (offlineUrl != null) {
      // Используем офлайн тайл
      final filePath = offlineUrl.replaceFirst('file://', '');
      final file = File(filePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    
    // Fallback на онлайн тайл
    final url = options.urlTemplate!
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{z}', coordinates.z.toString());
    
    return NetworkImage(url, headers: {
      'User-Agent': 'com.cyfishon.app',
    });
  }
}
