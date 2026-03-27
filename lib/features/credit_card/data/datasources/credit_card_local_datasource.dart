import '../../../../core/database/app_database.dart';
import '../models/credit_card_model.dart';

class CreditCardLocalDataSource {
  final AppDatabase database;

  CreditCardLocalDataSource(this.database);

  Future<void> createCreditCard(CreditCardModel card) async {
    final db = await database.database;

    await db.insert(
      'credit_cards',
      card.toMap(),
    );
  }

  Future<void> updateCreditCard(CreditCardModel card) async {
    final db = await database.database;

    await db.update(
      'credit_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteCreditCard(String cardId) async {
    final db = await database.database;

    await db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<bool> hasTransactionsLinkedToCard(String cardId) async {
    final db = await database.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM transactions
      WHERE credit_card_id = ?
      ''',
      [cardId],
    );

    final total = (result.first['total'] as int?) ?? 0;
    return total > 0;
  }

  Future<List<CreditCardModel>> getCreditCardsByUser(String userId) async {
    final db = await database.database;

    final result = await db.query(
      'credit_cards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return result.map(CreditCardModel.fromMap).toList();
  }
}