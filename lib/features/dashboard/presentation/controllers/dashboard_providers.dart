import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../credit_card/domain/entities/credit_card_entity.dart';
import '../../../credit_card/presentation/controllers/credit_card_providers.dart';
import '../../../transaction/domain/entities/finance_transaction.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../domain/entities/monthly_summary.dart';
import '../../domain/usecases/get_monthly_summary.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

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

final creditCardStatementsProvider =
    FutureProvider.family<List<CreditCardStatementView>, String>(
  (ref, userId) async {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final cards = await ref.watch(creditCardsProvider(userId).future);
    final transactions =
        await ref.watch(filteredTransactionsByMonthProvider(userId).future);

    final result = <CreditCardStatementView>[];

    for (final card in cards) {
      final cardTransactions = transactions.where((transaction) {
        return transaction.type == 'expense' &&
            transaction.creditCardId == card.id;
      }).toList();

      if (cardTransactions.isEmpty) {
        continue;
      }

      final totalAmount = cardTransactions.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      final allPaid =
          cardTransactions.every((transaction) => transaction.status == 'paid');

      final paidAtDates = cardTransactions
          .where((transaction) => transaction.paidAt != null)
          .map((transaction) => transaction.paidAt!)
          .toList()
        ..sort();

      result.add(
        CreditCardStatementView(
          card: card,
          totalAmount: totalAmount,
          itemsCount: cardTransactions.length,
          referenceMonth: selectedMonth,
          isPaid: allPaid,
          paidAt: allPaid && paidAtDates.isNotEmpty ? paidAtDates.last : null,
        ),
      );
    }

    return result;
  },
);

class CreditCardStatementView {
  final CreditCardEntity card;
  final double totalAmount;
  final int itemsCount;
  final DateTime referenceMonth;
  final bool isPaid;
  final DateTime? paidAt;

  const CreditCardStatementView({
    required this.card,
    required this.totalAmount,
    required this.itemsCount,
    required this.referenceMonth,
    required this.isPaid,
    required this.paidAt,
  });
}