import 'package:flutter/material.dart';

/// Виджет нижней навигации
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
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
    );
  }
}
