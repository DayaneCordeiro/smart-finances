import '../../../../core/database/app_database.dart';
import '../models/financing_contract_model.dart';
import '../models/financing_installment_model.dart';

class FinancingLocalDataSource {
  final AppDatabase database;

  FinancingLocalDataSource(this.database);

  Future<void> createFinancing(FinancingContractModel contract) async {
    final db = await database.database;
    await db.insert('financings', contract.toMap());
  }

  Future<void> createInstallments(
    List<FinancingInstallmentModel> installments,
  ) async {
    final db = await database.database;

    final batch = db.batch();
    for (final installment in installments) {
      batch.insert('financing_installments', installment.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<FinancingContractModel>> getFinancingsByUser(String userId) async {
    final db = await database.database;

    final result = await db.query(
      'financings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map(FinancingContractModel.fromMap).toList();
  }

  Future<List<FinancingInstallmentModel>> getInstallmentsByFinancing(
    String financingId,
  ) async {
    final db = await database.database;

    final result = await db.query(
      'financing_installments',
      where: 'financing_id = ?',
      whereArgs: [financingId],
      orderBy: 'installment_number ASC',
    );

    return result.map(FinancingInstallmentModel.fromMap).toList();
  }

  Future<void> updateInstallment(FinancingInstallmentModel installment) async {
    final db = await database.database;

    await db.update(
      'financing_installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }
}