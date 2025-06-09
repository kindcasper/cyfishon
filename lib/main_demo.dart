import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const CyFishOnDemoApp());
}

class CyFishOnDemoApp extends StatelessWidget {
  const CyFishOnDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyFishON Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      home: const DemoHomeScreen(),
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  String userName = 'Демо Пользователь';
  List<Map<String, dynamic>> recentCatches = [];
  String currentCoords = 'Получение координат...';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Симуляция получения координат
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          currentCoords = '35°10.123′N\n33°22.456′E';
        });
      }
    });
  }

  void _createCatch(String type) {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Симуляция создания поимки
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        final newCatch = {
          'type': type,
          'time': now,
          'user': userName,
          'sent': true,
        };

        setState(() {
          recentCatches.insert(0, newCatch);
          if (recentCatches.length > 3) {
            recentCatches.removeLast();
          }
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Поимка сохранена! $type'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _getTypeDisplay(String type) {
    switch (type) {
      case 'fishon':
        return 'FishON';
      case 'double':
        return 'Double';
      case 'triple':
        return 'Triple EPTA';
      default:
        return type;
    }
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return 'только что';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else {
      return '${diff.inHours} ч назад';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Привет, $userName!'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Это демо-версия. Настройки недоступны.'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Блок текущих координат
            Container(
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
                  const Icon(
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
                        Text(
                          currentCoords,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Блок последних поимок
            Container(
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
                  const Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Последние поимки',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentCatches.isEmpty)
                    const Text(
                      'Пока нет поимок',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    )
                  else
                    ...recentCatches.map((catch_) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: catch_['sent'] ? Colors.green : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _getTypeDisplay(catch_['type']),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '- ${_getTimeAgo(catch_['time'])}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      catch_['user'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),

            // Кнопки действий
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCatchButton(
                      type: 'fishon',
                      label: 'FishON',
                      color: Colors.green,
                      icon: Icons.phishing,
                    ),
                    const SizedBox(height: 16),
                    _buildCatchButton(
                      type: 'double',
                      label: 'Double',
                      color: Colors.orange,
                      icon: Icons.looks_two,
                    ),
                    const SizedBox(height: 16),
                    _buildCatchButton(
                      type: 'triple',
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          String message = '';
          switch (index) {
            case 0:
              message = 'Вы на главном экране';
              break;
            case 1:
              message = 'История поимок (демо)';
              break;
            case 2:
              message = 'Карта в разработке';
              break;
            case 3:
              message = 'Логи (демо)';
              break;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.phishing, size: 28),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt, size: 28),
            label: 'История',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map, size: 28),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 28),
            label: 'Логи',
          ),
        ],
      ),
    );
  }

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
        onPressed: isLoading ? null : () => _createCatch(type),
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
