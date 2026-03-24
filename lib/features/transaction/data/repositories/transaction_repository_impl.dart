import '../../domain/entities/finance_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../models/finance_transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDatasource localDatasource;

  TransactionRepositoryImpl(this.localDatasource);

  @override
  Future<void> createTransaction(FinanceTransaction transaction) async {
    await localDatasource.createTransaction(
      FinanceTransactionModel.fromEntity(transaction),
    );
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await localDatasource.deleteTransaction(transactionId);
  }

  @override
  Future<List<FinanceTransaction>> getTransactionsByUser(String userId) async {
    final transactions = await localDatasource.getTransactionsByUser(userId);
    return transactions.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> togglePaidStatus({
    required String transactionId,
    required bool isPaid,
  }) async {
    await localDatasource.togglePaidStatus(
      transactionId: transactionId,
      isPaid: isPaid,
    );
  }
}