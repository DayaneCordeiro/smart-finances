import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transaction/domain/entities/finance_transaction.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../domain/entities/monthly_summary.dart';
import '../../domain/usecases/get_monthly_summary.dart';

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void setMonth(DateTime value) {
    state = DateTime(value.year, value.month);
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

final getMonthlySummaryProvider = Provider<GetMonthlySummary>((ref) {
  return GetMonthlySummary();
});

final filteredTransactionsByMonthProvider =
    FutureProvider.family<List<FinanceTransaction>, String>((ref, userId) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final transactions = await ref.watch(transactionsProvider(userId).future);

  return transactions.where((transaction) {
    final referenceDate = transaction.type == 'expense'
        ? transaction.dueDate
        : transaction.receivedDate;

    if (referenceDate == null) return false;

    return referenceDate.year == selectedMonth.year &&
        referenceDate.month == selectedMonth.month;
  }).toList();
});

final monthlySummaryProvider =
    FutureProvider.family<MonthlySummary, String>((ref, userId) async {
  final transactions =
      await ref.watch(filteredTransactionsByMonthProvider(userId).future);
  final usecase = ref.read(getMonthlySummaryProvider);
  return usecase.call(transactions);
});

final dashboardActiveUserSummaryProvider =
    FutureProvider<MonthlySummary?>((ref) async {
  final activeUser = await ref.watch(activeUserProvider.future);

  if (activeUser == null) return null;

  return ref.watch(monthlySummaryProvider(activeUser.id).future);
});