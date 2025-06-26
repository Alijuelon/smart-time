import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rule_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static const int _dbVersion =
      2; // ⬅️ Naikkan versi DB kalau ada perubahan tabel
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rules.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            durationMinutes INTEGER,
            createdAt TEXT,
            isCompleted INTEGER,
            isViolated INTEGER,
            activeDays TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Dari versi lama ke versi 2 ➔ Tambah kolom activeDays
          await db.execute('ALTER TABLE rules ADD COLUMN activeDays TEXT');
        }
      },
    );
  }

  Future<int> insertRule(Rule rule) async {
    final db = await database;
    return await db.insert('rules', rule.toMap());
  }

  Future<List<Rule>> getRules() async {
    final db = await database;
    final maps = await db.query('rules', orderBy: 'createdAt DESC');
    return maps.map((map) => Rule.fromMap(map)).toList();
  }

  Future<int> updateRule(Rule rule) async {
    final db = await database;
    return await db.update(
      'rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRule(int id) async {
    final db = await database;
    return await db.delete('rules', where: 'id = ?', whereArgs: [id]);
  }
}
