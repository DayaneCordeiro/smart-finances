import '../entities/finance_transaction.dart';
import '../repositories/transaction_repository.dart';

class ReuseTransactionNextMonth {
  final TransactionRepository repository;

  ReuseTransactionNextMonth(this.repository);

  Future<void> call(FinanceTransaction transaction) async {
    final referenceDate = transaction.type == 'expense'
        ? transaction.dueDate
        : transaction.receivedDate;

    if (referenceDate == null) {
      throw Exception('Transação sem data base para reaproveitar');
    }

    final nextMonthDate = _addOneMonth(referenceDate);

    final duplicated = FinanceTransaction(
      id: transaction.id,
      userId: transaction.userId,
      categoryId: transaction.categoryId,
      type: transaction.type,
      description: transaction.description,
      amount: transaction.amount,
      dueDate: transaction.type == 'expense' ? nextMonthDate : null,
      receivedDate: transaction.type == 'income' ? nextMonthDate : null,
      status: 'pending',
      paidAt: null,
      createdAt: DateTime.now(),
    );

    await repository.createTransaction(duplicated);
  }

  DateTime _addOneMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;

    final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
    final safeDay = date.day > lastDay ? lastDay : date.day;

    return DateTime(nextYear, nextMonth, safeDay);
  }
}