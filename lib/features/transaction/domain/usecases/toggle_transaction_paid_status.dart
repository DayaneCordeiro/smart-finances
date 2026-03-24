import '../repositories/transaction_repository.dart';

class ToggleTransactionPaidStatus {
  final TransactionRepository repository;

  ToggleTransactionPaidStatus(this.repository);

  Future<void> call({
    required String transactionId,
    required bool isPaid,
  }) async {
    await repository.togglePaidStatus(
      transactionId: transactionId,
      isPaid: isPaid,
    );
  }
}