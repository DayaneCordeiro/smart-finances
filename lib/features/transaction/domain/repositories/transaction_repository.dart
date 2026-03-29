import '../entities/finance_transaction.dart';

abstract class TransactionRepository {
  Future<void> createTransaction(FinanceTransaction transaction);
  Future<void> updateTransaction(FinanceTransaction transaction);
  Future<void> deleteTransaction(String transactionId);
  Future<List<FinanceTransaction>> getTransactionsByUser(String userId);

  Future<void> updateStatus({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  });

  Future<void> payCreditCardBill({
    required String userId,
    required String creditCardId,
    required int year,
    required int month,
    required DateTime paidAt,
  });

  Future<void> updateTransactionByFinancingInstallmentId({
    required String financingInstallmentId,
    required String status,
    required DateTime? paidAt,
    required double paidAmount,
    required double discountAmount,
  });
}