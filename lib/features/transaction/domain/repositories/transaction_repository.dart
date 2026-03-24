import '../entities/finance_transaction.dart';

abstract class TransactionRepository {
  Future<void> createTransaction(FinanceTransaction transaction);
  Future<List<FinanceTransaction>> getTransactionsByUser(String userId);
  Future<void> togglePaidStatus({
    required String transactionId,
    required bool isPaid,
  });
  Future<void> deleteTransaction(String transactionId);
}