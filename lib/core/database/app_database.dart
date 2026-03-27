import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_finances_v2.db');

    _database = await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createCategoriesTable(db);
        await _createTransactionsTable(db);
        await _createCreditCardsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoriesTable(db);
        }

        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS transactions');
          await _createTransactionsTable(db);
        }

        if (oldVersion < 4) {
          await _ensureTransactionInstallmentColumns(db);
        }

        if (oldVersion < 5) {
          await _ensureTransactionCreditCardColumn(db);
          await _createCreditCardsTable(db);
        }

        if (oldVersion < 6) {
          await _ensureTransactionInstallmentColumns(db);
          await _ensureTransactionCreditCardColumn(db);
          await _createCreditCardsTable(db);
        }

        if (oldVersion < 7) {
          await _ensureTransactionStoreNameColumn(db);
        }
      },
      onOpen: (db) async {
        await _createUsersTable(db);
        await _createCategoriesTable(db);
        await _createTransactionsTable(db);
        await _createCreditCardsTable(db);

        await _ensureTransactionInstallmentColumns(db);
        await _ensureTransactionCreditCardColumn(db);
        await _ensureTransactionStoreNameColumn(db);
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
        store_name TEXT,
        amount REAL NOT NULL,
        due_date TEXT,
        received_date TEXT,
        status TEXT NOT NULL,
        paid_at TEXT,
        created_at TEXT NOT NULL,
        is_installment INTEGER NOT NULL DEFAULT 0,
        installment_group_id TEXT,
        installment_number INTEGER,
        installment_total INTEGER,
        installment_full_amount REAL,
        credit_card_id TEXT
      )
    ''');
  }

  Future<void> _createCreditCardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_cards (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        closing_day INTEGER NOT NULL,
        due_day INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureTransactionInstallmentColumns(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(transactions)");
    final columnNames = columns.map((item) => item['name'] as String).toSet();

    if (!columnNames.contains('is_installment')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN is_installment INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (!columnNames.contains('installment_group_id')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN installment_group_id TEXT',
      );
    }

    if (!columnNames.contains('installment_number')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN installment_number INTEGER',
      );
    }

    if (!columnNames.contains('installment_total')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN installment_total INTEGER',
      );
    }

    if (!columnNames.contains('installment_full_amount')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN installment_full_amount REAL',
      );
    }
  }

  Future<void> _ensureTransactionCreditCardColumn(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(transactions)");
    final columnNames = columns.map((item) => item['name'] as String).toSet();

    if (!columnNames.contains('credit_card_id')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN credit_card_id TEXT',
      );
    }
  }

  Future<void> _ensureTransactionStoreNameColumn(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(transactions)");
    final columnNames = columns.map((item) => item['name'] as String).toSet();

    if (!columnNames.contains('store_name')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN store_name TEXT',
      );
    }
  }
}