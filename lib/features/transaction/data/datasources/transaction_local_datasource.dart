import '../../../../core/database/app_database.dart';
import '../models/finance_transaction_model.dart';

class TransactionLocalDataSource {
  final AppDatabase database;

  TransactionLocalDataSource(this.database);

  Future<void> createTransaction(FinanceTransactionModel transaction) async {
    final db = await database.database;
    await db.insert('transactions', transaction.toMap());
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

    final result = await db.query(
      'transactions',
      where: '''
        user_id = ? AND
        credit_card_id = ? AND
        type = ? AND
        due_date IS NOT NULL
      ''',
      whereArgs: [userId, creditCardId, 'expense'],
    );

    for (final row in result) {
      final dueDateRaw = row['due_date'] as String?;
      if (dueDateRaw == null) continue;

      final amount = (row['amount'] as num).toDouble();
      if (amount <= 0) continue;

      final dueDate = DateTime.parse(dueDateRaw);
      if (dueDate.year == year && dueDate.month == month) {
        await db.update(
          'transactions',
          {
            'status': 'paid',
            'paid_at': paidAt.toIso8601String(),
            'paid_amount': row['amount'],
            'discount_amount': row['discount_amount'] ?? 0,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  Future<void> updateTransactionByFinancingInstallmentId({
    required String financingInstallmentId,
    required String status,
    required DateTime? paidAt,
    required double paidAmount,
    required double discountAmount,
  }) async {
    final db = await database.database;

    await db.update(
      'transactions',
      {
        'status': status,
        'paid_at': paidAt?.toIso8601String(),
        'paid_amount': paidAmount,
        'discount_amount': discountAmount,
      },
      where: 'financing_installment_id = ?',
      whereArgs: [financingInstallmentId],
    );
  }
}