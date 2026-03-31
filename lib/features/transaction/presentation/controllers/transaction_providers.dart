import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/finance_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions_by_user.dart';
import '../../domain/usecases/toggle_transaction_paid_status.dart';
import '../../domain/usecases/update_transaction.dart';
import 'transaction_controller.dart';

final transactionAppDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSource(ref.read(transactionAppDatabaseProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(transactionLocalDataSourceProvider));
});

final createTransactionUseCaseProvider = Provider<CreateTransaction>((ref) {
  return CreateTransaction(ref.read(transactionRepositoryProvider));
});

final getTransactionsByUserUseCaseProvider =
    Provider<GetTransactionsByUser>((ref) {
  return GetTransactionsByUser(ref.read(transactionRepositoryProvider));
});

final updateTransactionUseCaseProvider = Provider<UpdateTransaction>((ref) {
  return UpdateTransaction(ref.read(transactionRepositoryProvider));
});

final toggleTransactionPaidStatusUseCaseProvider =
    Provider<ToggleTransactionPaidStatus>((ref) {
  return ToggleTransactionPaidStatus(ref.read(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransaction>((ref) {
  return DeleteTransaction(ref.read(transactionRepositoryProvider));
});

final transactionControllerProvider = Provider<TransactionController>((ref) {
  return TransactionController(
    createTransactionUsecase: ref.read(createTransactionUseCaseProvider),
    updateTransactionUsecase: ref.read(updateTransactionUseCaseProvider),
    togglePaidStatusUsecase:
        ref.read(toggleTransactionPaidStatusUseCaseProvider),
    deleteTransactionUsecase: ref.read(deleteTransactionUseCaseProvider),
  );
});

final transactionsProvider =
    FutureProvider.family<List<FinanceTransaction>, String>((ref, userId) async {
  return ref.read(getTransactionsByUserUseCaseProvider)(userId);
});