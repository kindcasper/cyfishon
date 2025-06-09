import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/name_input_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/log_service.dart';

void main() async {
  // Инициализация Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация базы данных
  await DatabaseService().database;
  
  // Логируем запуск приложения
  await LogService().logAppStart();
  
  runApp(const CyFishOnApp());
}

class CyFishOnApp extends StatelessWidget {
  const CyFishOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyFishON',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Большие кнопки для использования на море
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
      // Поддержка русского языка
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
      home: const AppStartScreen(),
    );
  }
}

/// Экран для определения начального маршрута
class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Показываем splash screen на секунду
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(AppConfig.keyUserName);
    
    if (!mounted) return;
    
    if (userName == null || userName.isEmpty) {
      // Первый запуск - показываем экран ввода имени
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const NameInputScreen(),
        ),
      );
    } else {
      // Имя уже есть - переходим на главный экран
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(userName: userName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
