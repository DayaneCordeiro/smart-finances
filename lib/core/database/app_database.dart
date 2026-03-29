import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/default_categories.dart';

class AppDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_finances_v2.db');

    _database = await openDatabase(
      path,
      version: 10,
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createCategoriesTable(db);
        await _createTransactionsTable(db);
        await _createCreditCardsTable(db);
        await _createFinancingsTable(db);
        await _createFinancingInstallmentsTable(db);
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

        if (oldVersion < 8) {
          await _createFinancingsTable(db);
          await _createFinancingInstallmentsTable(db);
        }

        if (oldVersion < 9) {
          await _ensureTransactionFinancingColumns(db);
        }

        if (oldVersion < 10) {
          await _ensureDefaultCategoriesForAllUsers(db);
        }
      },
      onOpen: (db) async {
        await _createUsersTable(db);
        await _createCategoriesTable(db);
        await _createTransactionsTable(db);
        await _createCreditCardsTable(db);
        await _createFinancingsTable(db);
        await _createFinancingInstallmentsTable(db);

        await _ensureTransactionInstallmentColumns(db);
        await _ensureTransactionCreditCardColumn(db);
        await _ensureTransactionStoreNameColumn(db);
        await _ensureTransactionFinancingColumns(db);

        await _ensureDefaultCategoriesForAllUsers(db);
      },
    );

    return _database!;
  }

  Future<void> ensureDefaultCategoriesForUser(String userId) async {
    final db = await database;
    await _ensureDefaultCategoriesForUser(db, userId);
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
        credit_card_id TEXT,
        financing_id TEXT,
        financing_installment_id TEXT,
        paid_amount REAL,
        discount_amount REAL NOT NULL DEFAULT 0
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

  Future<void> _createFinancingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        asset_name TEXT NOT NULL,
        description TEXT,
        total_amount REAL NOT NULL,
        total_installments INTEGER NOT NULL,
        first_due_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFinancingInstallmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financing_installments (
        id TEXT PRIMARY KEY,
        financing_id TEXT NOT NULL,
        installment_number INTEGER NOT NULL,
        original_amount REAL NOT NULL,
        paid_amount REAL,
        discount_amount REAL NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL,
        paid_at TEXT,
        status TEXT NOT NULL
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

  Future<void> _ensureTransactionFinancingColumns(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(transactions)");
    final columnNames = columns.map((item) => item['name'] as String).toSet();

    if (!columnNames.contains('financing_id')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN financing_id TEXT',
      );
    }

    if (!columnNames.contains('financing_installment_id')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN financing_installment_id TEXT',
      );
    }

    if (!columnNames.contains('paid_amount')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN paid_amount REAL',
      );
    }

    if (!columnNames.contains('discount_amount')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _ensureDefaultCategoriesForAllUsers(Database db) async {
    final users = await db.query('users', columns: ['id']);

    for (final user in users) {
      final userId = user['id'] as String?;
      if (userId == null || userId.isEmpty) continue;
      await _ensureDefaultCategoriesForUser(db, userId);
    }
  }

  Future<void> _ensureDefaultCategoriesForUser(
    Database db,
    String userId,
  ) async {
    for (final category in defaultExpenseCategories) {
      final existing = await db.query(
        'categories',
        columns: ['id'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [category.id, userId],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert('categories', {
          'id': category.id,
          'user_id': userId,
          'name': category.name,
          'type': category.type,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
}