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

    final nextMonthDate = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      referenceDate.day,
    );

    final duplicated = FinanceTransaction(
      id: transaction.id,
      userId: transaction.userId,
      categoryId: transaction.categoryId,
      type: transaction.type,
      description: transaction.description,
      storeName: transaction.storeName,
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
      creditCardId: transaction.creditCardId,
      financingId: null,
      financingInstallmentId: null,
      paidAmount: null,
      discountAmount: 0,
    );

    await repository.createTransaction(duplicated);
  }
}