import '../../../../core/database/app_database.dart';
import '../models/finance_transaction_model.dart';

class TransactionLocalDataSource {
  final AppDatabase database;

  TransactionLocalDataSource(this.database);

  Future<void> createTransaction(FinanceTransactionModel transaction) async {
    final db = await database.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
    );
  }

  Future<void> updateTransaction(FinanceTransactionModel transaction) async {
    final db = await database.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await database.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<List<FinanceTransactionModel>> getTransactionsByUser(
    String userId,
  ) async {
    final db = await database.database;

    final result = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map(FinanceTransactionModel.fromMap).toList();
  }

  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  }) async {
    final db = await database.database;

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

  Future<void> payCreditCardBill({
    required String userId,
    required String creditCardId,
    required int year,
    required int month,
    required DateTime paidAt,
  }) async {
    final db = await database.database;

    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    await db.update(
      'transactions',
      {
        'status': 'paid',
        'paid_at': paidAt.toIso8601String(),
      },
      where: '''
        user_id = ?
        AND credit_card_id = ?
        AND type = ?
        AND due_date >= ?
        AND due_date < ?
        AND status != ?
      ''',
      whereArgs: [
        userId,
        creditCardId,
        'expense',
        start,
        end,
        'paid',
      ],
    );
  }
}