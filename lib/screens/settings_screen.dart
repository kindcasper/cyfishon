import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/log_service.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../utils/version_utils.dart';

/// Экран настроек
class SettingsScreen extends StatefulWidget {
  final String userName;

  const SettingsScreen({
    super.key,
    required this.userName,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LogService _log = LogService();
  final SyncService _sync = SyncService();
  final DatabaseService _db = DatabaseService();
  
  final _nameController = TextEditingController();
  int _retryInterval = AppConfig.defaultRetryMinutes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Загрузить настройки
  Future<void> _loadSettings() async {
    try {
      final interval = await _sync.getRetryInterval();
      if (mounted) {
        setState(() {
          _retryInterval = interval;
        });
      }
    } catch (e) {
      await _log.error('Ошибка загрузки настроек', e);
    }
  }

  /// Сохранить имя пользователя
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя не может быть пустым'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName.length > AppConfig.maxUserNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Имя не может быть длиннее ${AppConfig.maxUserNameLength} символов'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName == widget.userName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя не изменилось'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.keyUserName, newName);
      
      await _log.logUserNameSet(newName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Имя сохранено'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Возвращаемся назад с новым именем
        Navigator.pop(context, newName);
      }
    } catch (e) {
      await _log.error('Ошибка сохранения имени', e);
      
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

  /// Сохранить интервал повторных попыток
  Future<void> _saveRetryInterval(int minutes) async {
    try {
      await _sync.setRetryInterval(minutes);
      setState(() {
        _retryInterval = minutes;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Интервал сохранен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      await _log.error('Ошибка сохранения интервала', e);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Показать диалог выбора интервала
  Future<void> _showRetryIntervalDialog() async {
    final intervals = [1, 2, 5, 10, 15, 30, 60];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интервал повторных попыток'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text('$interval ${interval == 1 ? 'минута' : interval < 5 ? 'минуты' : 'минут'}'),
              value: interval,
              groupValue: _retryInterval,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (selected != null && selected != _retryInterval) {
      await _saveRetryInterval(selected);
    }
  }

  /// Очистить все данные
  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные'),
        content: const Text(
          'Это удалит все поимки и логи. Действие нельзя отменить. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _log.clearAllLogs();
        // Здесь можно добавить очистку поимок если нужно
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные очищены'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        await _log.error('Ошибка очистки данных', e);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Получить статистику
  Future<Map<String, dynamic>> _getStatistics() async {
    try {
      return await _db.getStatistics();
    } catch (e) {
      await _log.error('Ошибка получения статистики', e);
      return {'total': 0, 'sent': 0, 'pending': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Настройки пользователя
            _buildSection(
              title: 'Пользователь',
              children: [
                _buildNameSetting(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Настройки синхронизации
            _buildSection(
              title: 'Синхронизация',
              children: [
                _buildRetryIntervalSetting(),
                _buildSyncStatusCard(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Статистика
            _buildSection(
              title: 'Статистика',
              children: [
                _buildStatisticsCard(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // О приложении
            _buildSection(
              title: 'О приложении',
              children: [
                _buildAboutCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Секция настроек
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Настройка имени
  Widget _buildNameSetting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Имя пользователя',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              maxLength: AppConfig.maxUserNameLength,
              decoration: const InputDecoration(
                labelText: 'Ваше имя',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveName,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Настройка интервала повторных попыток
  Widget _buildRetryIntervalSetting() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('Интервал повторных попыток'),
        subtitle: Text('$_retryInterval ${_retryInterval == 1 ? 'минута' : _retryInterval < 5 ? 'минуты' : 'минут'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showRetryIntervalDialog,
      ),
    );
  }

  /// Карточка статуса синхронизации
  Widget _buildSyncStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _sync.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _sync.isOnline ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sync.isOnline ? 'Онлайн' : 'Офлайн',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _sync.isOnline
                        ? 'Синхронизация активна'
                        : 'Нет подключения к интернету',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка статистики
  Widget _buildStatisticsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStatistics(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'sent': 0, 'pending': 0};
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Всего', stats['total'], Colors.blue),
                    _buildStatItem('Отправлено', stats['sent'], Colors.green),
                    _buildStatItem('Ожидает', stats['pending'], Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Элемент статистики
  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }


  /// О приложении
  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CyFishON',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: VersionUtils.getAppVersion(),
              builder: (context, snapshot) {
                final version = snapshot.data ?? '1.0.0';
                return Text(
                  'Версия $version',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Приложение для сообщества рыбаков Кипра. Позволяет быстро делиться информацией о поимках тунца.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Разработано с учетом работы в море при отсутствии стабильного интернета.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
