import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions_by_user.dart';
import '../../domain/usecases/toggle_transaction_paid_status.dart';
import '../../domain/usecases/update_transaction.dart';
import 'transaction_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSource(ref.read(appDatabaseProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(transactionLocalDataSourceProvider));
});

final createTransactionProvider = Provider<CreateTransaction>((ref) {
  return CreateTransaction(ref.read(transactionRepositoryProvider));
});

final updateTransactionProvider = Provider<UpdateTransaction>((ref) {
  return UpdateTransaction(ref.read(transactionRepositoryProvider));
});

final toggleTransactionPaidStatusProvider =
    Provider<ToggleTransactionPaidStatus>((ref) {
  return ToggleTransactionPaidStatus(ref.read(transactionRepositoryProvider));
});

final deleteTransactionProvider = Provider<DeleteTransaction>((ref) {
  return DeleteTransaction(ref.read(transactionRepositoryProvider));
});

final getTransactionsByUserProvider = Provider<GetTransactionsByUser>((ref) {
  return GetTransactionsByUser(ref.read(transactionRepositoryProvider));
});

final transactionControllerProvider = Provider<TransactionController>((ref) {
  return TransactionController(
    createTransactionUsecase: ref.read(createTransactionProvider),
    updateTransactionUsecase: ref.read(updateTransactionProvider),
    togglePaidStatusUsecase: ref.read(toggleTransactionPaidStatusProvider),
    deleteTransactionUsecase: ref.read(deleteTransactionProvider),
  );
});

final transactionsProvider = FutureProvider.family((ref, String userId) async {
  final usecase = ref.read(getTransactionsByUserProvider);
  return usecase(userId);
});