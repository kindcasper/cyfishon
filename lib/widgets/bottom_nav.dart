import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.phishing, size: 28),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list_alt, size: 28),
          label: l10n.history,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map, size: 28),
          label: l10n.map,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.description, size: 28),
          label: l10n.logs,
        ),
      ],
    );
  }
}
