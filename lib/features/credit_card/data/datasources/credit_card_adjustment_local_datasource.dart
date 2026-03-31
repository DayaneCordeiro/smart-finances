import '../../../../core/database/app_database.dart';
import '../../domain/entities/credit_card_adjustment.dart';

class CreditCardAdjustmentLocalDataSource {
  final AppDatabase database;

  CreditCardAdjustmentLocalDataSource(this.database);

  Future<void> createAdjustment(CreditCardAdjustment adjustment) async {
    final db = await database.database;

    await db.insert(
      'credit_card_adjustments',
      {
        'id': adjustment.id,
        'user_id': adjustment.userId,
        'credit_card_id': adjustment.creditCardId,
        'type': adjustment.type,
        'amount': adjustment.amount,
        'adjustment_date': adjustment.adjustmentDate.toIso8601String(),
        'description': adjustment.description,
        'related_transaction_id': adjustment.relatedTransactionId,
        'created_at': adjustment.createdAt.toIso8601String(),
      },
    );
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
      return CreditCardAdjustment(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        creditCardId: row['credit_card_id'] as String,
        type: row['type'] as String,
        amount: (row['amount'] as num).toDouble(),
        adjustmentDate: DateTime.parse(row['adjustment_date'] as String),
        description: row['description'] as String,
        relatedTransactionId: row['related_transaction_id'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }
}