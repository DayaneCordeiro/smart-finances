import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_finances.db');

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createCategoriesTable(db);
        await _createTransactionsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoriesTable(db);
        }

        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS transactions');
          await _createTransactionsTable(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        password TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT,
        received_date TEXT,
        status TEXT NOT NULL,
        paid_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }
}