import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../domain/entities/monthly_summary.dart';
import '../../domain/usecases/get_monthly_summary.dart';

final getMonthlySummaryProvider = Provider<GetMonthlySummary>((ref) {
  return GetMonthlySummary();
});

final monthlyTransactionsProvider =
    FutureProvider.family((ref, String userId) async {
  final transactions =
      await ref.read(getTransactionsByUserProvider).call(userId);

  final now = DateTime.now();

  return transactions.where((transaction) {
    final referenceDate = transaction.type == 'expense'
        ? transaction.dueDate
        : transaction.receivedDate;

    if (referenceDate == null) return false;

    return referenceDate.year == now.year && referenceDate.month == now.month;
  }).toList();
});

final monthlySummaryProvider =
    FutureProvider.family<MonthlySummary, String>((ref, userId) async {
  final transactions = await ref.watch(monthlyTransactionsProvider(userId).future);
  final usecase = ref.read(getMonthlySummaryProvider);
  return usecase.call(transactions);
});

final dashboardActiveUserSummaryProvider =
    FutureProvider<MonthlySummary?>((ref) async {
  final activeUser = await ref.watch(activeUserProvider.future);

  if (activeUser == null) return null;

  return ref.watch(monthlySummaryProvider(activeUser.id).future);
});