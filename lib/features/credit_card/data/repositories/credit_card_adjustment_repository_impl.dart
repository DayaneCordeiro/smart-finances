import '../../domain/entities/credit_card_adjustment.dart';
import '../../domain/repositories/credit_card_adjustment_repository.dart';
import '../datasources/credit_card_adjustment_local_datasource.dart';

class CreditCardAdjustmentRepositoryImpl
    implements CreditCardAdjustmentRepository {
  final CreditCardAdjustmentLocalDataSource localDataSource;

  CreditCardAdjustmentRepositoryImpl(this.localDataSource);

  @override
  Future<void> createAdjustment(CreditCardAdjustment adjustment) {
    return localDataSource.createAdjustment(adjustment);
  }

  @override
  Future<List<CreditCardAdjustment>> getAdjustmentsByCard({
    required String userId,
    required String creditCardId,
  }) {
    return localDataSource.getAdjustmentsByCard(
      userId: userId,
      creditCardId: creditCardId,
    );
  }
}