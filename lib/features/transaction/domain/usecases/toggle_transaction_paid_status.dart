import '../repositories/transaction_repository.dart';

class ToggleTransactionPaidStatus {
  final TransactionRepository repository;

  ToggleTransactionPaidStatus(this.repository);

  Future<void> call({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  }) async {
    await repository.updateStatus(
      transactionId: transactionId,
      status: status,
      paidAt: paidAt,
    );
  }
}