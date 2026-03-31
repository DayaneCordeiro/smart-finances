import '../entities/credit_card_adjustment.dart';

abstract class CreditCardAdjustmentRepository {
  Future<void> createAdjustment(CreditCardAdjustment adjustment);

  Future<List<CreditCardAdjustment>> getAdjustmentsByCard({
    required String userId,
    required String creditCardId,
  });

  Future<void> updateRemainingAmount({
    required String adjustmentId,
    required double remainingAmount,
  });
}