import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../credit_card/domain/entities/credit_card_adjustment.dart';
import '../../../credit_card/domain/entities/credit_card_entity.dart';
import '../../../credit_card/presentation/controllers/credit_card_adjustment_providers.dart';
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
    final transactions = await ref.watch(transactionsProvider(userId).future);

    final result = <CreditCardStatementView>[];

    for (final card in cards) {
      final cardTransactions = transactions.where((transaction) {
        if (transaction.type != 'expense') return false;
        if (transaction.creditCardId != card.id) return false;
        if (transaction.dueDate == null) return false;

        final dueDate = transaction.dueDate!;
        return dueDate.year == selectedMonth.year &&
            dueDate.month == selectedMonth.month;
      }).toList()
        ..sort((a, b) {
          final aDate = a.dueDate ?? a.createdAt;
          final bDate = b.dueDate ?? b.createdAt;
          return aDate.compareTo(bDate);
        });

      final adjustments = await ref.watch(
        creditCardAdjustmentsByCardProvider(
          CreditCardAdjustmentQuery(
            userId: userId,
            creditCardId: card.id,
          ),
        ).future,
      );

      final purchasesAmount = cardTransactions.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      final availableCredit = _calculateAvailableCreditForMonth(
        month: selectedMonth,
        transactions: transactions
            .where((t) => t.creditCardId == card.id && t.type == 'expense')
            .toList(),
        adjustments: adjustments,
      );

      final appliedCredit = min(purchasesAmount, availableCredit).toDouble();
      final carryOverCredit =
          max(0.0, availableCredit - purchasesAmount).toDouble();
      final totalAmount =
          max(0.0, purchasesAmount - appliedCredit).toDouble();

      final allPaid = cardTransactions.isNotEmpty &&
          cardTransactions.every((transaction) => transaction.status == 'paid');

      final paidAtDates = cardTransactions
          .where((transaction) => transaction.paidAt != null)
          .map((transaction) => transaction.paidAt!)
          .toList()
        ..sort();

      if (cardTransactions.isEmpty &&
          purchasesAmount == 0 &&
          availableCredit == 0 &&
          totalAmount == 0) {
        continue;
      }

      result.add(
        CreditCardStatementView(
          card: card,
          totalAmount: totalAmount,
          purchasesAmount: purchasesAmount,
          appliedCredit: appliedCredit,
          carryOverCredit: carryOverCredit,
          itemsCount: cardTransactions.length,
          referenceMonth: selectedMonth,
          isPaid: totalAmount == 0 || allPaid,
          paidAt: (totalAmount == 0 || allPaid) && paidAtDates.isNotEmpty
              ? paidAtDates.last
              : null,
        ),
      );
    }

    return result;
  },
);

double _calculateAvailableCreditForMonth({
  required DateTime month,
  required List<FinanceTransaction> transactions,
  required List<CreditCardAdjustment> adjustments,
}) {
  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  final creditsFromPreviousMonths = adjustments.where((adjustment) {
    return adjustment.adjustmentDate.isBefore(monthStart);
  }).fold<double>(
    0,
    (sum, item) => sum + item.remainingAmount,
  );

  final creditsThisMonth = adjustments.where((adjustment) {
    final date = adjustment.adjustmentDate;
    return !date.isBefore(monthStart) && !date.isAfter(monthEnd);
  }).fold<double>(
    0,
    (sum, item) => sum + item.amount,
  );

  return (creditsFromPreviousMonths + creditsThisMonth).toDouble();
}

class CreditCardStatementView {
  final CreditCardEntity card;
  final double totalAmount;
  final double purchasesAmount;
  final double appliedCredit;
  final double carryOverCredit;
  final int itemsCount;
  final DateTime referenceMonth;
  final bool isPaid;
  final DateTime? paidAt;

  const CreditCardStatementView({
    required this.card,
    required this.totalAmount,
    required this.purchasesAmount,
    required this.appliedCredit,
    required this.carryOverCredit,
    required this.itemsCount,
    required this.referenceMonth,
    required this.isPaid,
    required this.paidAt,
  });
}