import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/credit_card_model.dart';

class CreditCardLocalDatasource {
  final AppDatabase appDatabase;

  CreditCardLocalDatasource(this.appDatabase);

  Future<Database> get _db async => appDatabase.database;

  Future<void> createCard(CreditCardModel card) async {
    final db = await _db;
    await db.insert('credit_cards', card.toMap());
  }

  Future<List<CreditCardModel>> getCardsByUser(String userId) async {
    final db = await _db;

    final result = await db.query(
      'credit_cards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return result.map(CreditCardModel.fromMap).toList();
  }
}