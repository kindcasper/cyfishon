import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';

/// Экран приветствия с выбором авторизации
class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Логотип и название
              _buildHeader(),
              
              const SizedBox(height: 60),
              
              // Описание
              _buildDescription(),
              
              const SizedBox(height: 60),
              
              // Кнопки
              _buildButtons(context),
              
              const Spacer(),
              
              // Версия приложения
              _buildVersion(),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок с логотипом
  Widget _buildHeader() {
    return Column(
      children: [
        // Иконка приложения
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.phishing,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Название приложения
        const Text(
          'CyFishON',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Подзаголовок
        Text(
          'Сообщество рыбаков Кипра',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Описание приложения
  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          Text(
            'Добро пожаловать!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте аккаунт или войдите в существующий, чтобы начать делиться своими уловами с сообществом рыбаков.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопки действий
  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Кнопка регистрации
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _navigateToRegister(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 24),
                SizedBox(width: 12),
                Text(
                  'Создать аккаунт',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Кнопка входа
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _navigateToLogin(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 24),
                SizedBox(width: 12),
                Text(
                  'Войти в аккаунт',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Версия приложения
  Widget _buildVersion() {
    return Text(
      'Версия 1.3.0',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
    );
  }

  /// Переход к регистрации
  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  /// Переход к входу
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
