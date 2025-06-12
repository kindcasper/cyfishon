import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/log_service.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/locale_service.dart';
import '../utils/version_utils.dart';
import '../screens/auth_welcome_screen.dart';
import '../l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nameCannotBeEmpty),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName.length > AppConfig.maxUserNameLength) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.nameCannotBeLonger} ${AppConfig.maxUserNameLength} ${l10n.symbols}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName == widget.userName) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nameNotChanged),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = UserService();
      
      // Сохраняем имя через UserService
      await userService.setUserName(newName);
      
      await _log.logUserNameSet(newName);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.nameSaved),
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
      
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.intervalSaved),
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
    final l10n = AppLocalizations.of(context);
    final intervals = [1, 2, 5, 10, 15, 30, 60];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.retryInterval),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            String minuteText;
            if (interval == 1) {
              minuteText = l10n.minute;
            } else if (interval < 5) {
              minuteText = l10n.minutes2to4;
            } else {
              minuteText = l10n.minutes5plus;
            }
            
            return RadioListTile<int>(
              title: Text('$interval $minuteText'),
              value: interval,
              groupValue: _retryInterval,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selected != null && selected != _retryInterval) {
      await _saveRetryInterval(selected);
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
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(l10n.settings),
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
              title: l10n.user,
              children: [
                _buildNameSetting(),
                const SizedBox(height: 12),
                _buildLanguageSetting(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Настройки синхронизации
            _buildSection(
              title: l10n.sync,
              children: [
                _buildRetryIntervalSetting(),
                _buildSyncStatusCard(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Статистика
            _buildSection(
              title: l10n.statistics,
              children: [
                _buildStatisticsCard(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // О приложении
            _buildSection(
              title: l10n.about,
              children: [
                _buildAboutCard(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Аккаунт
            _buildSection(
              title: l10n.account,
              children: [
                _buildSignOutCard(),
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
    final l10n = AppLocalizations.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              maxLength: AppConfig.maxUserNameLength,
              decoration: InputDecoration(
                labelText: l10n.enterName,
                border: const OutlineInputBorder(),
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
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Настройка интервала повторных попыток
  Widget _buildRetryIntervalSetting() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(l10n.retryInterval),
        subtitle: Text('$_retryInterval ${l10n.minutesShort}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showRetryIntervalDialog,
      ),
    );
  }

  /// Карточка статуса синхронизации
  Widget _buildSyncStatusCard() {
    final l10n = AppLocalizations.of(context);
    
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
                    _sync.isOnline ? l10n.online : l10n.offline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _sync.isOnline
                        ? l10n.syncActive
                        : l10n.noInternetConnection,
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
    final l10n = AppLocalizations.of(context);
    
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
                    _buildStatItem(l10n.total, stats['total'], Colors.blue),
                    _buildStatItem(l10n.sent, stats['sent'], Colors.green),
                    _buildStatItem(l10n.pending, stats['pending'], Colors.orange),
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
    final l10n = AppLocalizations.of(context);
    
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
                  '${l10n.version} $version',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              l10n.appDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.developedForSea,
              style: const TextStyle(
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

  /// Карточка выхода из аккаунта
  Widget _buildSignOutCard() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.authorizedAs}:',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (AuthService.currentUser != null)
                        Text(
                          AuthService.currentUser!.email,
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  l10n.logout,
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Настройка языка
  Widget _buildLanguageSetting() {
    final l10n = AppLocalizations.of(context);
    
    return ListenableBuilder(
      listenable: LocaleService(),
      builder: (context, child) {
        final localeService = LocaleService();
        final currentLanguage = localeService.currentLocale.languageCode;
        final languageName = localeService.getLanguageName(currentLanguage);
        
        return Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.languageLabel),
            subtitle: Text(languageName),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageDialog,
          ),
        );
      },
    );
  }

  /// Показать диалог выбора языка
  Future<void> _showLanguageDialog() async {
    final l10n = AppLocalizations.of(context);
    final localeService = LocaleService();
    final currentLocale = localeService.currentLocale;
    
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            final languageName = localeService.getLanguageName(locale.languageCode);
            return RadioListTile<Locale>(
              title: Text(languageName),
              value: locale,
              groupValue: currentLocale,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelSlashCancel),
          ),
        ],
      ),
    );

    if (selected != null && selected != currentLocale) {
      await localeService.setLocale(selected);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.languageChanged),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Выход из аккаунта
  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Выполняем выход
        await AuthService.logout();
        
        if (mounted) {
          // При выходе всегда переходим к стартовому экрану авторизации
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AuthWelcomeScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        await _log.error('Ошибка при выходе из аккаунта', e);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
