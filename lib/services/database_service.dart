import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/app_config.dart';
import '../models/catch_record.dart';
import '../models/log_entry.dart';

/// Сервис для работы с локальной базой данных SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Получить экземпляр базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConfig.databaseName);

    return await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    // Таблица поимок
    await db.execute('''
      CREATE TABLE catches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        catch_type TEXT NOT NULL,
        telegram_status TEXT DEFAULT '${AppConfig.statusPending}',
        server_status TEXT DEFAULT '${AppConfig.statusPending}',
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Индексы для поимок
    await db.execute(
        'CREATE INDEX idx_catches_timestamp ON catches(timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_catches_user_name ON catches(user_name)');
    await db.execute(
        'CREATE INDEX idx_catches_telegram_status ON catches(telegram_status)');

    // Таблица логов
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        details TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Индексы для логов
    await db.execute(
        'CREATE INDEX idx_logs_timestamp ON logs(timestamp DESC)');
    await db.execute('CREATE INDEX idx_logs_level ON logs(level)');
  }

  /// Обновление структуры БД при изменении версии
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Здесь будут миграции при обновлении структуры БД
  }

  // ============= Операции с поимками =============

  /// Добавить новую поимку
  Future<int> insertCatch(CatchRecord record) async {
    final db = await database;
    return await db.insert('catches', record.toMap());
  }

  /// Получить список поимок
  Future<List<CatchRecord>> getCatches({
    String? userName,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userName != null) {
      whereClause = 'user_name = ?';
      whereArgs = [userName];
    }
    
    final maps = await db.query(
      'catches',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => CatchRecord.fromMap(map)).toList();
  }

  /// Получить последние поимки для главного экрана
  Future<List<CatchRecord>> getRecentCatches({int limit = 3}) async {
    final db = await database;
    final maps = await db.query(
      'catches',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return maps.map((map) => CatchRecord.fromMap(map)).toList();
  }

  /// Получить поимки, ожидающие отправки
  Future<List<CatchRecord>> getPendingCatches() async {
    final db = await database;
    final maps = await db.query(
      'catches',
      where: 'telegram_status = ? OR telegram_status = ?',
      whereArgs: [AppConfig.statusPending, AppConfig.statusFailed],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((map) => CatchRecord.fromMap(map)).toList();
  }

  /// Обновить статус поимки
  Future<void> updateCatchStatus(
    int id,
    String telegramStatus, {
    String? lastError,
    int? retryCount,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'telegram_status': telegramStatus,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (lastError != null) {
      updates['last_error'] = lastError;
    }
    
    if (retryCount != null) {
      updates['retry_count'] = retryCount;
    }
    
    await db.update(
      'catches',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Увеличить счетчик попыток
  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE catches SET retry_count = retry_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  // ============= Операции с логами =============

  /// Добавить запись в лог
  Future<void> insertLog(LogEntry log) async {
    final db = await database;
    await db.insert('logs', log.toMap());
  }

  /// Получить логи
  Future<List<LogEntry>> getLogs({
    String? level,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (level != null) {
      whereClause = 'level = ?';
      whereArgs = [level];
    }
    
    final maps = await db.query(
      'logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit ?? 100,
      offset: offset,
    );
    
    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  /// Очистить старые логи
  Future<void> clearOldLogs() async {
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: AppConfig.logsRetentionDays))
        .millisecondsSinceEpoch;
    
    await db.delete(
      'logs',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// Очистить все логи
  Future<void> clearAllLogs() async {
    final db = await database;
    await db.delete('logs');
  }

  // ============= Утилиты =============

  /// Получить статистику
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    // Общее количество поимок
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM catches'),
    ) ?? 0;
    
    // Количество отправленных
    final sentCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM catches WHERE telegram_status = ?',
        [AppConfig.statusSent],
      ),
    ) ?? 0;
    
    // Количество ожидающих
    final pendingCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM catches WHERE telegram_status = ? OR telegram_status = ?',
        [AppConfig.statusPending, AppConfig.statusFailed],
      ),
    ) ?? 0;
    
    return {
      'total': totalCount,
      'sent': sentCount,
      'pending': pendingCount,
    };
  }

  /// Закрыть базу данных
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
