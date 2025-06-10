import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/catch_record.dart';
import '../config/app_config.dart';

/// Виджет для отображения маркера текущего местоположения с направлением компаса
class CurrentLocationMarker extends StatelessWidget {
  final LatLng position;
  final double heading;
  final double size;

  const CurrentLocationMarker({
    super.key,
    required this.position,
    required this.heading,
    this.size = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (math.pi / 180.0),
      child: Icon(
        Icons.navigation,
        color: Colors.blue,
        size: size,
        shadows: const [
          Shadow(
            color: Colors.white,
            blurRadius: 2.0,
            offset: Offset(0, 0),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения маркера поимки рыбы
class CatchMarker extends StatelessWidget {
  final CatchRecord catchRecord;
  final VoidCallback onTap;
  final double size;

  const CatchMarker({
    super.key,
    required this.catchRecord,
    required this.onTap,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getCatchColor(),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.phishing,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  Color _getCatchColor() {
    switch (catchRecord.catchType) {
      case AppConfig.catchTypeFishOn:
        return Colors.green;
      case AppConfig.catchTypeDouble:
        return Colors.blue;
      case AppConfig.catchTypeTriple:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Виджет для отображения всплывающего хинта с информацией о поимке
class CatchTooltip extends StatefulWidget {
  final CatchRecord catchRecord;
  final LatLng position;
  final VoidCallback onDismiss;

  const CatchTooltip({
    super.key,
    required this.catchRecord,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<CatchTooltip> createState() => _CatchTooltipState();
}

class _CatchTooltipState extends State<CatchTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Автоматическое скрытие через 3 секунды
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      _dismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.catchRecord.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.catchRecord.catchTypeDisplay,
                  style: TextStyle(
                    color: _getCatchColor(),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.catchRecord.timeAgo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCatchColor() {
    switch (widget.catchRecord.catchType) {
      case AppConfig.catchTypeFishOn:
        return Colors.green;
      case AppConfig.catchTypeDouble:
        return Colors.blue;
      case AppConfig.catchTypeTriple:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Виджет для отображения информации о карте
class MapInfoPanel extends StatelessWidget {
  final int totalCatches;
  final String currentLocation;
  final double currentHeading;

  const MapInfoPanel({
    super.key,
    required this.totalCatches,
    required this.currentLocation,
    required this.currentHeading,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phishing, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '$totalCatches ${_getCatchesText(totalCatches)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  _getDirectionText(currentHeading),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCatchesText(int count) {
    // Используем локализацию для слова "поимок"
    return 'поимок'; // Временно, пока не добавим контекст локализации
  }

  String _getDirectionText(double heading) {
    const directions = [
      'С', 'ССВ', 'СВ', 'ВСВ',
      'В', 'ВЮВ', 'ЮВ', 'ЮЮВ',
      'Ю', 'ЮЮЗ', 'ЮЗ', 'ЗЮЗ',
      'З', 'ЗСЗ', 'СЗ', 'ССЗ'
    ];
    
    final index = ((heading + 11.25) / 22.5).floor() % 16;
    return '${directions[index]} (${heading.round()}°)';
  }
}
