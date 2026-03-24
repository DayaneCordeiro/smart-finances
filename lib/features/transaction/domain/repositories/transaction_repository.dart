import '../entities/finance_transaction.dart';

abstract class TransactionRepository {
  Future<void> createTransaction(FinanceTransaction transaction);
  Future<List<FinanceTransaction>> getTransactionsByUser(String userId);
  Future<void> updateStatus({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  });
  Future<void> deleteTransaction(String transactionId);
}