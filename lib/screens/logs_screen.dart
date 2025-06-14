import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/log_entry.dart';
import '../services/log_service.dart';
import '../widgets/bottom_nav.dart';
import '../l10n/app_localizations.dart';

/// Экран логов
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final LogService _log = LogService();
  
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  String? _selectedLevel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Загрузить логи
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _log.getLogs(
        level: _selectedLevel,
        limit: 200,
      );
      
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).loadingLogsError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Очистить все логи
  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).clearLogsTitle),
        content: Text(AppLocalizations.of(context).clearLogsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _log.clearAllLogs();
        await _loadLogs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).logsCleared),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context).clearingError}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Изменить фильтр уровня
  void _changeFilter(String? level) {
    setState(() {
      _selectedLevel = level;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).logs),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllLogs();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).clearAllLogs),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).filterByLevel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context).all),
                      selected: _selectedLevel == null,
                      onSelected: (selected) {
                        if (selected) _changeFilter(null);
                      },
                    ),
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context).infoLogs),
                      selected: _selectedLevel == AppConfig.logLevelInfo,
                      onSelected: (selected) {
                        if (selected) _changeFilter(AppConfig.logLevelInfo);
                      },
                    ),
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context).warningLogs),
                      selected: _selectedLevel == AppConfig.logLevelWarning,
                      onSelected: (selected) {
                        if (selected) _changeFilter(AppConfig.logLevelWarning);
                      },
                    ),
                    ChoiceChip(
                      label: Text(AppLocalizations.of(context).errorLogs),
                      selected: _selectedLevel == AppConfig.logLevelError,
                      onSelected: (selected) {
                        if (selected) _changeFilter(AppConfig.logLevelError);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Список логов
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).noLogs,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return _buildLogCard(_logs[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Карточка лога
  Widget _buildLogCard(LogEntry log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                // Индикатор уровня
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(log.levelColor),
                  ),
                ),
                const SizedBox(width: 8),
                // Время
                Text(
                  log.formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                // Уровень
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(log.levelColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.level.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(log.levelColor),
                    ),
                  ),
                ),
                const Spacer(),
                // Дата
                Text(
                  log.formattedDate,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Сообщение
            Text(
              log.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            // Детали (если есть)
            if (log.details != null && log.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.details!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
