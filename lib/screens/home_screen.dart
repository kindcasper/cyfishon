import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../models/catch_record.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/log_service.dart';
import '../services/sync_service.dart';
import '../widgets/bottom_nav.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

/// Главный экран приложения
class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({
    super.key,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final LocationService _location = LocationService();
  final LogService _log = LogService();
  final SyncService _sync = SyncService();

  int _currentIndex = 0;
  List<CatchRecord> _recentCatches = [];
  Position? _currentPosition;
  DateTime? _lastLocationUpdate;
  Timer? _locationTimer;
  Timer? _uiUpdateTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startLocationTracking();
    _loadRecentCatches();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _sync.stopSync();
    super.dispose();
  }

  /// Инициализация сервисов
  Future<void> _initializeServices() async {
    // Запускаем синхронизацию
    await _sync.startSync();
    
    // Запускаем таймер обновления UI
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Запуск отслеживания координат
  void _startLocationTracking() {
    // Получаем координаты сразу
    _updateLocation();
    
    // Запускаем периодическое обновление
    _locationTimer = Timer.periodic(
      Duration(seconds: AppConfig.locationUpdateSeconds),
      (_) => _updateLocation(),
    );
  }

  /// Обновить текущие координаты
  Future<void> _updateLocation() async {
    try {
      final position = await _location.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _lastLocationUpdate = DateTime.now();
        });
      }
    } catch (e) {
      await _log.error('Ошибка обновления координат', e);
    }
  }

  /// Загрузить последние поимки
  Future<void> _loadRecentCatches() async {
    try {
      final catches = await _db.getRecentCatches(limit: AppConfig.maxRecentCatches);
      if (mounted) {
        setState(() {
          _recentCatches = catches;
        });
      }
    } catch (e) {
      await _log.error('Ошибка загрузки последних поимок', e);
    }
  }

  /// Создать новую поимку
  Future<void> _createCatch(String catchType) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Запрашиваем координаты
      await _log.logLocationRequest();
      
      final position = await _location.getCurrentLocation();
      if (position == null) {
        // Проверяем статус разрешений для более детальной ошибки
        final permissionStatus = await _location.getPermissionStatus();
        await _showLocationPermissionDialog(permissionStatus);
        return;
      }

      // Создаем запись о поимке
      final catchRecord = CatchRecord(
        timestamp: DateTime.now(),
        userName: widget.userName,
        latitude: position.latitude,
        longitude: position.longitude,
        catchType: catchType,
      );

      // Сохраняем в базу данных
      await _db.insertCatch(catchRecord);
      await _log.logCatchCreated(catchType, widget.userName);

      // Обновляем список последних поимок
      await _loadRecentCatches();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Поимка сохранена! ${catchRecord.catchTypeDisplay}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Запускаем синхронизацию
      _sync.forceSyncNow();
    } catch (e) {
      await _log.error('Ошибка создания поимки', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Получить время с последнего обновления координат
  String get _timeSinceUpdate {
    if (_lastLocationUpdate == null) return '';
    
    final seconds = DateTime.now().difference(_lastLocationUpdate!).inSeconds;
    if (seconds < 3) return '';
    
    return '${seconds}с';
  }

  /// Переключение между экранами
  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Навигация к другим экранам
    switch (index) {
      case 1: // История
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(userName: widget.userName),
          ),
        ).then((_) {
          setState(() {
            _currentIndex = 0;
          });
          _loadRecentCatches();
        });
        break;
      case 2: // Карта
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MapScreen(),
          ),
        ).then((_) {
          setState(() {
            _currentIndex = 0;
          });
        });
        break;
      case 3: // Логи
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LogsScreen(),
          ),
        ).then((_) {
          setState(() {
            _currentIndex = 0;
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Привет, ${widget.userName}!'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(userName: widget.userName),
                ),
              ).then((_) => _loadRecentCatches());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Блок текущих координат
            _buildLocationCard(),
            
            // Блок последних поимок
            _buildRecentCatchesCard(),
            
            // Кнопки действий
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCatchButton(
                      type: AppConfig.catchTypeFishOn,
                      label: 'FishON',
                      color: Colors.green,
                      icon: Icons.phishing,
                    ),
                    const SizedBox(height: 16),
                    _buildCatchButton(
                      type: AppConfig.catchTypeDouble,
                      label: 'Double',
                      color: Colors.orange,
                      icon: Icons.looks_two,
                    ),
                    const SizedBox(height: 16),
                    _buildCatchButton(
                      type: AppConfig.catchTypeTriple,
                      label: 'Triple EPTA',
                      color: Colors.red,
                      icon: Icons.looks_3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  /// Карточка с текущими координатами
  Widget _buildLocationCard() {
    final formattedCoords = _currentPosition != null
        ? _location.formatPosition(_currentPosition!)
        : null;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Текущие координаты',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (formattedCoords != null) ...[
                  Text(
                    formattedCoords['latitude']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    formattedCoords['longitude']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Colors.black54,
                    ),
                  ),
                ] else
                  const Text(
                    'Получение координат...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (_timeSinceUpdate.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _timeSinceUpdate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Карточка с последними поимками
  Widget _buildRecentCatchesCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(userName: widget.userName),
          ),
        ).then((_) => _loadRecentCatches());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Последние поимки',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentCatches.isEmpty)
              const Text(
                'Пока нет поимок',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              )
            else
              ..._recentCatches.map((catch_) => _buildCatchItem(catch_)),
          ],
        ),
      ),
    );
  }

  /// Элемент поимки
  Widget _buildCatchItem(CatchRecord catch_) {
    final isMyName = catch_.userName == widget.userName;
    final formattedCoords = _location.formatPosition(
      Position(
        latitude: catch_.latitude,
        longitude: catch_.longitude,
        timestamp: catch_.timestamp,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Индикатор статуса
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: catch_.isSentToTelegram ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          // Информация о поимке
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      catch_.catchTypeDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '- ${catch_.timeAgo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  catch_.userName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isMyName ? FontWeight.bold : FontWeight.normal,
                    color: isMyName ? Colors.blue : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Координаты справа
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedCoords['latitude']!,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.black54,
                ),
              ),
              Text(
                formattedCoords['longitude']!,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Показать диалог с проблемой разрешений
  Future<void> _showLocationPermissionDialog(String permissionStatus) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нужно разрешение на геолокацию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус: $permissionStatus'),
            const SizedBox(height: 16),
            const Text(
              'Для создания поимки необходимо разрешение на использование геолокации.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Пожалуйста, предоставьте разрешение в настройках.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _location.openAppSettings();
            },
            child: const Text('Открыть настройки'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Повторная попытка запроса разрешения
              final hasPermission = await _location.checkPermissions();
              if (hasPermission) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Разрешение получено!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _updateLocation(); // Обновляем координаты
              }
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Кнопка поимки
  Widget _buildCatchButton({
    required String type,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _createCatch(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
