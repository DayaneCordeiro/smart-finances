import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../transaction/domain/entities/finance_transaction.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../domain/entities/credit_card_adjustment.dart';
import '../../domain/entities/credit_card_entity.dart';
import 'credit_card_adjustment_providers.dart';
import 'credit_card_providers.dart';

@immutable
class CreditCardStatementMonthQuery {
  final String userId;
  final String creditCardId;
  final DateTime month;

  const CreditCardStatementMonthQuery({
    required this.userId,
    required this.creditCardId,
    required this.month,
  });

  @override
  bool operator ==(Object other) {
    return other is CreditCardStatementMonthQuery &&
        other.userId == userId &&
        other.creditCardId == creditCardId &&
        other.month.year == month.year &&
        other.month.month == month.month;
  }

  @override
  int get hashCode => Object.hash(userId, creditCardId, month.year, month.month);
}

class CreditCardStatementMonthData {
  final List<FinanceTransaction> monthTransactions;
  final List<CreditCardAdjustment> monthAdjustments;
  final double purchasesTotal;
  final double monthAdjustmentsTotal;
  final double availableCredit;
  final double appliedCredit;
  final double carryOverCredit;
  final double finalTotal;

  const CreditCardStatementMonthData({
    required this.monthTransactions,
    required this.monthAdjustments,
    required this.purchasesTotal,
    required this.monthAdjustmentsTotal,
    required this.availableCredit,
    required this.appliedCredit,
    required this.carryOverCredit,
    required this.finalTotal,
  });
}

class CreditCardStatementSummary {
  final CreditCardEntity card;
  final DateTime referenceMonth;
  final double purchasesAmount;
  final double availableCredit;
  final double appliedCredit;
  final double carryOverCredit;
  final double totalAmount;
  final int itemsCount;
  final bool isPaid;
  final DateTime? paidAt;

  const CreditCardStatementSummary({
    required this.card,
    required this.referenceMonth,
    required this.purchasesAmount,
    required this.availableCredit,
    required this.appliedCredit,
    required this.carryOverCredit,
    required this.totalAmount,
    required this.itemsCount,
    required this.isPaid,
    required this.paidAt,
  });
}

final creditCardStatementMonthProvider = FutureProvider.family<
    CreditCardStatementMonthData,
    CreditCardStatementMonthQuery>((ref, query) async {
  final transactions = await ref.watch(transactionsProvider(query.userId).future);
  final adjustments = await ref.watch(
    creditCardAdjustmentsByCardProvider(
      CreditCardAdjustmentQuery(
        userId: query.userId,
        creditCardId: query.creditCardId,
      ),
    ).future,
  );

  final monthTransactions = transactions.where((transaction) {
    if (transaction.type != 'expense') return false;
    if (transaction.creditCardId != query.creditCardId) return false;
    if (transaction.dueDate == null) return false;

    final dueDate = transaction.dueDate!;
    return dueDate.year == query.month.year &&
        dueDate.month == query.month.month;
  }).toList()
    ..sort((a, b) {
      final aDate = a.dueDate ?? a.createdAt;
      final bDate = b.dueDate ?? b.createdAt;
      return aDate.compareTo(bDate);
    });

  final monthAdjustments = adjustments.where((adjustment) {
    final date = adjustment.adjustmentDate;
    return date.year == query.month.year && date.month == query.month.month;
  }).toList()
    ..sort((a, b) => a.adjustmentDate.compareTo(b.adjustmentDate));

  final purchasesTotal = monthTransactions.fold<double>(
    0,
    (sum, item) => sum + item.amount,
  );

  final monthAdjustmentsTotal = monthAdjustments.fold<double>(
    0,
    (sum, item) => sum + item.amount,
  );

  final availableCredit = _calculateAvailableCreditForMonth(
    month: query.month,
    transactions: transactions
        .where((t) => t.creditCardId == query.creditCardId && t.type == 'expense')
        .toList(),
    adjustments: adjustments,
  );

  final appliedCredit = min(purchasesTotal, availableCredit).toDouble();
  final carryOverCredit = max(0.0, availableCredit - purchasesTotal).toDouble();
  final finalTotal = max(0.0, purchasesTotal - appliedCredit).toDouble();

  return CreditCardStatementMonthData(
    monthTransactions: monthTransactions,
    monthAdjustments: monthAdjustments,
    purchasesTotal: purchasesTotal,
    monthAdjustmentsTotal: monthAdjustmentsTotal,
    availableCredit: availableCredit,
    appliedCredit: appliedCredit,
    carryOverCredit: carryOverCredit,
    finalTotal: finalTotal,
  );
});

final creditCardStatementSummariesProvider =
    FutureProvider.family<List<CreditCardStatementSummary>, String>(
  (ref, userId) async {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final cards = await ref.watch(creditCardsProvider(userId).future);
    final transactions = await ref.watch(transactionsProvider(userId).future);

    final summaries = <CreditCardStatementSummary>[];

    for (final card in cards) {
      final monthTransactions = transactions.where((transaction) {
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

      final adjustments = await ref.read(
        creditCardAdjustmentsByCardProvider(
          CreditCardAdjustmentQuery(
            userId: userId,
            creditCardId: card.id,
          ),
        ).future,
      );

      final purchasesAmount = monthTransactions.fold<double>(
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

      DateTime? paidAt;
      if (monthTransactions.isNotEmpty &&
          monthTransactions.every((t) => t.status == 'paid')) {
        final paidDates = monthTransactions
            .map((t) => t.paidAt)
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => b.compareTo(a));

        if (paidDates.isNotEmpty) {
          paidAt = paidDates.first;
        }
      }

      if (monthTransactions.isEmpty &&
          purchasesAmount == 0 &&
          availableCredit == 0 &&
          totalAmount == 0) {
        continue;
      }

      summaries.add(
        CreditCardStatementSummary(
          card: card,
          referenceMonth: DateTime(selectedMonth.year, selectedMonth.month),
          purchasesAmount: purchasesAmount,
          availableCredit: availableCredit,
          appliedCredit: appliedCredit,
          carryOverCredit: carryOverCredit,
          totalAmount: totalAmount,
          itemsCount: monthTransactions.length,
          isPaid: totalAmount == 0,
          paidAt: paidAt,
        ),
      );
    }

    return summaries;
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

class CreditCardStatementActions {
  final Ref ref;

  CreditCardStatementActions(this.ref);

  Future<void> payStatement({
    required String userId,
    required String creditCardId,
    required DateTime referenceMonth,
    required DateTime paidAt,
  }) async {
    final transactions = await ref.read(transactionsProvider(userId).future);

    final monthTransactions = transactions.where((transaction) {
      if (transaction.type != 'expense') return false;
      if (transaction.creditCardId != creditCardId) return false;
      if (transaction.dueDate == null) return false;

      final dueDate = transaction.dueDate!;
      return dueDate.year == referenceMonth.year &&
          dueDate.month == referenceMonth.month &&
          transaction.status != 'paid';
    }).toList();

    for (final transaction in monthTransactions) {
      await ref.read(transactionControllerProvider).updateStatus(
            transactionId: transaction.id,
            status: 'paid',
            paidAt: paidAt,
          );
    }

    ref.invalidate(transactionsProvider(userId));
    ref.invalidate(creditCardStatementSummariesProvider(userId));
    ref.invalidate(monthlySummaryProvider(userId));
    ref.invalidate(dashboardActiveUserSummaryProvider);
  }
}

final creditCardStatementActionsProvider =
    Provider<CreditCardStatementActions>((ref) {
  return CreditCardStatementActions(ref);
});