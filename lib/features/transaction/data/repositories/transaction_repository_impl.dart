import '../../domain/entities/finance_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../models/finance_transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl(this.localDataSource);

  @override
  Future<void> createTransaction(FinanceTransaction transaction) async {
    await localDataSource.createTransaction(
      FinanceTransactionModel.fromEntity(transaction),
    );
  }

  @override
  Future<void> updateTransaction(FinanceTransaction transaction) async {
    await localDataSource.updateTransaction(
      FinanceTransactionModel.fromEntity(transaction),
    );
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await localDataSource.deleteTransaction(transactionId);
  }

  @override
  Future<List<FinanceTransaction>> getTransactionsByUser(String userId) async {
    final models = await localDataSource.getTransactionsByUser(userId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateStatus({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  }) async {
    await localDataSource.updateTransactionStatus(
      transactionId: transactionId,
      status: status,
      paidAt: paidAt,
    );
  }

  @override
  Future<void> payCreditCardBill({
    required String userId,
    required String creditCardId,
    required int year,
    required int month,
    required DateTime paidAt,
  }) async {
    await localDataSource.payCreditCardBill(
      userId: userId,
      creditCardId: creditCardId,
      year: year,
      month: month,
      paidAt: paidAt,
    );
  }
}