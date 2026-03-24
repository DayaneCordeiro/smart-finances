import '../../../transaction/domain/entities/finance_transaction.dart';
import '../entities/monthly_summary.dart';

class GetMonthlySummary {
  MonthlySummary call(List<FinanceTransaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    double paidOrReceivedTotal = 0;
    double pendingTotal = 0;
    int overdueCount = 0;

    for (final transaction in transactions) {
      final effectiveStatus = _effectiveStatus(transaction);

      final isRealized =
          effectiveStatus == 'paid' || effectiveStatus == 'received';
      final isPendingLike =
          effectiveStatus == 'pending' || effectiveStatus == 'overdue';

      if (transaction.type == 'income') {
        if (effectiveStatus == 'received') {
          totalIncome += transaction.amount;
        }

        if (isPendingLike) {
          pendingTotal += transaction.amount;
        }
      }

      if (transaction.type == 'expense') {
        if (effectiveStatus == 'paid') {
          totalExpense += transaction.amount;
        }

        if (isPendingLike) {
          pendingTotal += transaction.amount;
        }
      }

      if (isRealized) {
        paidOrReceivedTotal += transaction.amount;
      }

      if (effectiveStatus == 'overdue') {
        overdueCount++;
      }
    }

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      paidOrReceivedTotal: paidOrReceivedTotal,
      pendingTotal: pendingTotal,
      overdueCount: overdueCount,
      balance: totalIncome - totalExpense,
    );
  }

  String _effectiveStatus(FinanceTransaction transaction) {
    if (transaction.status == 'paid' || transaction.status == 'received') {
      return transaction.status;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (transaction.type == 'expense' && transaction.dueDate != null) {
      final dueDate = DateTime(
        transaction.dueDate!.year,
        transaction.dueDate!.month,
        transaction.dueDate!.day,
      );

      if (transaction.status == 'pending' && dueDate.isBefore(today)) {
        return 'overdue';
      }
    }

    if (transaction.type == 'income' && transaction.receivedDate != null) {
      final receivedDate = DateTime(
        transaction.receivedDate!.year,
        transaction.receivedDate!.month,
        transaction.receivedDate!.day,
      );

      if (transaction.status == 'pending' && receivedDate.isBefore(today)) {
        return 'overdue';
      }
    }

    return transaction.status;
  }
}