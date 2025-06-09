import 'dart:async';
import '../models/catch_record.dart';

/// Сервис для уведомлений об обновлениях данных
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Контроллеры для стримов уведомлений
  final StreamController<List<CatchRecord>> _newCatchesController = 
      StreamController<List<CatchRecord>>.broadcast();
  
  final StreamController<bool> _dataUpdatedController = 
      StreamController<bool>.broadcast();

  /// Стрим новых поимок с сервера
  Stream<List<CatchRecord>> get newCatchesStream => _newCatchesController.stream;
  
  /// Стрим уведомлений об обновлении данных
  Stream<bool> get dataUpdatedStream => _dataUpdatedController.stream;

  /// Уведомить о новых поимках с сервера
  void notifyNewCatches(List<CatchRecord> newCatches) {
    if (newCatches.isNotEmpty) {
      _newCatchesController.add(newCatches);
      _dataUpdatedController.add(true);
    }
  }

  /// Уведомить об обновлении данных
  void notifyDataUpdated() {
    _dataUpdatedController.add(true);
  }

  /// Закрыть стримы
  void dispose() {
    _newCatchesController.close();
    _dataUpdatedController.close();
  }
}
