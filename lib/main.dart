import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/log_service.dart';
import 'services/server_sync_service.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'l10n/app_localizations_delegate.dart';

void main() async {
  // Инициализация Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация базы данных
  await DatabaseService().database;
  
  // Инициализация локализации
  await LocaleService().initialize();
  
  // Логируем запуск приложения
  await LogService().logAppStart();
  
  // Запускаем синхронизацию с сервера
  final serverSync = ServerSyncService();
  serverSync.startAutoSync();
  
  // Выполняем первую синхронизацию сразу при запуске
  serverSync.syncFromServer();
  
  runApp(const CyFishOnApp());
}

class CyFishOnApp extends StatelessWidget {
  const CyFishOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService(),
      builder: (context, child) {
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
          // Поддержка локализации
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
          locale: LocaleService().currentLocale,
          home: const AppStartScreen(),
        );
      },
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
    
    if (!mounted) return;
    
    // Проверяем авторизацию
    final isLoggedIn = await AuthService.autoLogin();
    
    if (isLoggedIn) {
      // Пользователь авторизован - переходим на главный экран
      final user = AuthService.currentUser;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(userName: user!.name),
        ),
      );
    } else {
      // Пользователь не авторизован - показываем экран авторизации
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
