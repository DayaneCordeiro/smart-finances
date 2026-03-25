import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/finance_transaction_model.dart';

class TransactionLocalDatasource {
  final AppDatabase appDatabase;

  TransactionLocalDatasource(this.appDatabase);

  Future<Database> get _db async => appDatabase.database;

  Future<void> createTransaction(FinanceTransactionModel transaction) async {
    final db = await _db;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<FinanceTransactionModel>> getTransactionsByUser(
    String userId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: '''
        CASE
          WHEN due_date IS NOT NULL THEN due_date
          ELSE received_date
        END DESC,
        created_at DESC
      ''',
    );

    return result.map(FinanceTransactionModel.fromMap).toList();
  }

  Future<void> updateStatus({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  }) async {
    final db = await _db;

    await db.update(
      'transactions',
      {
        'status': status,
        'paid_at': paidAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await _db;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}