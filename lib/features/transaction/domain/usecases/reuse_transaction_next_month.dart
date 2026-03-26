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
      throw Exception('Transação sem data base');
    }

    final nextMonthDate = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      referenceDate.day,
    );

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
      isInstallment: false,
      installmentGroupId: null,
      installmentNumber: null,
      installmentTotal: null,
      installmentFullAmount: null,

      // 🔥 CORREÇÃO
      creditCardId: transaction.creditCardId,
    );

    await repository.createTransaction(duplicated);
  }
}