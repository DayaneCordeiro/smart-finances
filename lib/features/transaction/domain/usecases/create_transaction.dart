import '../entities/finance_transaction.dart';
import '../repositories/transaction_repository.dart';

class CreateTransaction {
  final TransactionRepository repository;

  CreateTransaction(this.repository);

  Future<void> call(FinanceTransaction transaction) async {
    await repository.createTransaction(transaction);
  }
}