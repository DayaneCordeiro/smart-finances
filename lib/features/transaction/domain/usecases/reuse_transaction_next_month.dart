import 'package:uuid/uuid.dart';

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

    final nextMonthDate = _addMonths(referenceDate, 1);

    final duplicated = FinanceTransaction(
      id: const Uuid().v4(),
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

      // 🔥 NOVOS CAMPOS (isso resolve o erro)
      isInstallment: false,
      installmentGroupId: null,
      installmentNumber: null,
      installmentTotal: null,
      installmentFullAmount: null,
    );

    await repository.createTransaction(duplicated);
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    int year = date.year;
    int month = date.month + monthsToAdd;

    while (month > 12) {
      month -= 12;
      year++;
    }

    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final safeDay =
        date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime(year, month, safeDay);
  }
}