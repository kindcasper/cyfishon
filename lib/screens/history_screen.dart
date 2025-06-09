import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/catch_record.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/log_service.dart';
import '../widgets/bottom_nav.dart';

/// Экран истории поимок
class HistoryScreen extends StatefulWidget {
  final String userName;

  const HistoryScreen({
    super.key,
    required this.userName,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final LocationService _location = LocationService();
  final LogService _log = LogService();

  List<CatchRecord> _catches = [];
  bool _isLoading = true;
  bool _showOnlyMine = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCatches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Загрузить поимки
  Future<void> _loadCatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final catches = await _db.getCatches(
        userName: _showOnlyMine ? widget.userName : null,
      );
      
      if (mounted) {
        setState(() {
          _catches = catches;
          _isLoading = false;
        });
      }
    } catch (e) {
      await _log.error('Ошибка загрузки истории', e);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Переключить фильтр
  void _toggleFilter() {
    setState(() {
      _showOnlyMine = !_showOnlyMine;
    });
    _loadCatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('История поимок'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Фильтр
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Фильтр:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Все поимки'),
                  selected: !_showOnlyMine,
                  onSelected: (selected) {
                    if (selected && _showOnlyMine) {
                      _toggleFilter();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Только мои'),
                  selected: _showOnlyMine,
                  onSelected: (selected) {
                    if (selected && !_showOnlyMine) {
                      _toggleFilter();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Список поимок
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _catches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phishing,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyMine
                                  ? 'У вас пока нет поимок'
                                  : 'Пока нет поимок',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCatches,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _catches.length,
                          itemBuilder: (context, index) {
                            return _buildCatchCard(_catches[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Карточка поимки
  Widget _buildCatchCard(CatchRecord catch_) {
    final isMyName = catch_.userName == widget.userName;
    final formattedCoords = {
      'latitude': _location.formatCoordinate(catch_.latitude, true),
      'longitude': _location.formatCoordinate(catch_.longitude, false),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                // Индикатор статуса
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: catch_.isSentToTelegram ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                // Тип поимки
                Text(
                  catch_.catchTypeDisplay,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Время
                Text(
                  catch_.timeAgo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Имя пользователя
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  catch_.userName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isMyName ? FontWeight.bold : FontWeight.normal,
                    color: isMyName ? Colors.blue : Colors.black87,
                  ),
                ),
                if (isMyName) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Моя',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            
            // Координаты
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Координаты:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedCoords['latitude']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    formattedCoords['longitude']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            // Статус отправки
            if (!catch_.isSentToTelegram) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    catch_.isPending
                        ? 'Ожидает отправки'
                        : 'Ошибка отправки (попытка ${catch_.retryCount})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
            
            // Дата и время
            const SizedBox(height: 8),
            Text(
              '${catch_.timestamp.day.toString().padLeft(2, '0')}.${catch_.timestamp.month.toString().padLeft(2, '0')}.${catch_.timestamp.year} '
              '${catch_.timestamp.hour.toString().padLeft(2, '0')}:${catch_.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
