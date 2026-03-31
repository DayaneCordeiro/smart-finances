import '../../../../core/database/app_database.dart';
import '../../domain/entities/credit_card_adjustment.dart';

class CreditCardAdjustmentLocalDataSource {
  final AppDatabase database;

  CreditCardAdjustmentLocalDataSource(this.database);

  Future<void> createAdjustment(CreditCardAdjustment adjustment) async {
    final db = await database.database;

    await db.transaction((txn) async {
      await txn.insert(
        'credit_card_adjustments',
        {
          'id': adjustment.id,
          'user_id': adjustment.userId,
          'credit_card_id': adjustment.creditCardId,
          'type': adjustment.type,
          'amount': adjustment.amount,
          'remaining_amount': adjustment.remainingAmount,
          'adjustment_date': adjustment.adjustmentDate.toIso8601String(),
          'description': adjustment.description,
          'related_transaction_id': adjustment.relatedTransactionId,
          'created_at': adjustment.createdAt.toIso8601String(),
        },
      );

      await _applyAdjustmentToCurrentMonthTransactions(
        txn,
        adjustment: adjustment,
      );
    });
  }

  Future<List<CreditCardAdjustment>> getAdjustmentsByCard({
    required String userId,
    required String creditCardId,
  }) async {
    final db = await database.database;

    final result = await db.query(
      'credit_card_adjustments',
      where: 'user_id = ? AND credit_card_id = ?',
      whereArgs: [userId, creditCardId],
      orderBy: 'adjustment_date DESC, created_at DESC',
    );

    return result.map((row) {
      final amount = (row['amount'] as num).toDouble();
      final remainingRaw = row['remaining_amount'];

      return CreditCardAdjustment(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        creditCardId: row['credit_card_id'] as String,
        type: row['type'] as String,
        amount: amount,
        remainingAmount: remainingRaw == null
            ? amount
            : (remainingRaw as num).toDouble(),
        adjustmentDate: DateTime.parse(row['adjustment_date'] as String),
        description: row['description'] as String,
        relatedTransactionId: row['related_transaction_id'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<void> updateRemainingAmount({
    required String adjustmentId,
    required double remainingAmount,
  }) async {
    final db = await database.database;

    await db.update(
      'credit_card_adjustments',
      {
        'remaining_amount': remainingAmount,
      },
      where: 'id = ?',
      whereArgs: [adjustmentId],
    );
  }

  Future<void> _applyAdjustmentToCurrentMonthTransactions(
    dynamic txn, {
    required CreditCardAdjustment adjustment,
  }) async {
    final monthStart = DateTime(
      adjustment.adjustmentDate.year,
      adjustment.adjustmentDate.month,
      1,
    );
    final nextMonthStart = DateTime(
      adjustment.adjustmentDate.year,
      adjustment.adjustmentDate.month + 1,
      1,
    );

    final transactions = await txn.query(
      'transactions',
      where: '''
        user_id = ? AND
        credit_card_id = ? AND
        type = ? AND
        status != ? AND
        due_date IS NOT NULL
      ''',
      whereArgs: [
        adjustment.userId,
        adjustment.creditCardId,
        'expense',
        'paid',
      ],
      orderBy: 'due_date ASC, created_at ASC',
    );

    double remainingCredit = adjustment.remainingAmount;

    for (final row in transactions) {
      if (remainingCredit <= 0) break;

      final dueDateRaw = row['due_date'] as String?;
      if (dueDateRaw == null) continue;

      final dueDate = DateTime.tryParse(dueDateRaw);
      if (dueDate == null) continue;

      final inSameMonth = !dueDate.isBefore(monthStart) &&
          dueDate.isBefore(nextMonthStart);

      if (!inSameMonth) continue;

      final amount = (row['amount'] as num).toDouble();

      if (remainingCredit >= amount) {
        await txn.update(
          'transactions',
          {
            'status': 'paid',
            'paid_at': adjustment.adjustmentDate.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );

        remainingCredit -= amount;
      }
    }

    await txn.update(
      'credit_card_adjustments',
      {
        'remaining_amount': remainingCredit,
      },
      where: 'id = ?',
      whereArgs: [adjustment.id],
    );
  }
}