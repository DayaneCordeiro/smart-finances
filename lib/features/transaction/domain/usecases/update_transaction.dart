import '../entities/finance_transaction.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransaction {
  final TransactionRepository repository;

  UpdateTransaction(this.repository);

  Future<void> call(FinanceTransaction transaction) async {
    await repository.updateTransaction(transaction);
  }
}