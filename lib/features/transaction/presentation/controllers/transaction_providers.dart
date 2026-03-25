import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions_by_user.dart';
import '../../domain/usecases/toggle_transaction_paid_status.dart';
import '../../domain/usecases/update_transaction.dart';
import 'transaction_controller.dart';

final transactionLocalDatasourceProvider =
    Provider<TransactionLocalDatasource>((ref) {
  return TransactionLocalDatasource(ref.read(appDatabaseProvider));
});

final transactionRepositoryProvider =
    Provider<TransactionRepositoryImpl>((ref) {
  return TransactionRepositoryImpl(ref.read(transactionLocalDatasourceProvider));
});

final createTransactionProvider = Provider<CreateTransaction>((ref) {
  return CreateTransaction(ref.read(transactionRepositoryProvider));
});

final updateTransactionProvider = Provider<UpdateTransaction>((ref) {
  return UpdateTransaction(ref.read(transactionRepositoryProvider));
});

final getTransactionsByUserProvider = Provider<GetTransactionsByUser>((ref) {
  return GetTransactionsByUser(ref.read(transactionRepositoryProvider));
});

final toggleTransactionPaidStatusProvider =
    Provider<ToggleTransactionPaidStatus>((ref) {
  return ToggleTransactionPaidStatus(ref.read(transactionRepositoryProvider));
});

final deleteTransactionProvider = Provider<DeleteTransaction>((ref) {
  return DeleteTransaction(ref.read(transactionRepositoryProvider));
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
  return ref.read(getTransactionsByUserProvider).call(userId);
});