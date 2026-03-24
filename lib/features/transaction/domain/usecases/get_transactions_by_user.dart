import '../entities/finance_transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsByUser {
  final TransactionRepository repository;

  GetTransactionsByUser(this.repository);

  Future<List<FinanceTransaction>> call(String userId) async {
    return repository.getTransactionsByUser(userId);
  }
}