import 'package:uuid/uuid.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/toggle_transaction_paid_status.dart';
import '../../domain/usecases/update_transaction.dart';

class TransactionController {
  final CreateTransaction createTransactionUsecase;
  final UpdateTransaction updateTransactionUsecase;
  final ToggleTransactionPaidStatus togglePaidStatusUsecase;
  final DeleteTransaction deleteTransactionUsecase;

  TransactionController({
    required this.createTransactionUsecase,
    required this.updateTransactionUsecase,
    required this.togglePaidStatusUsecase,
    required this.deleteTransactionUsecase,
  });

  Future<void> createTransaction({
    required String userId,
    required String categoryId,
    required String type,
    required String description,
    required double amount,
    required DateTime? dueDate,
    required DateTime? receivedDate,
    required String status,
    required DateTime? paidAt,
    required String? creditCardId,
  }) async {
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception('Descrição é obrigatória');
    }

    if (amount <= 0) {
      throw Exception('Valor deve ser maior que zero');
    }

    if (type == 'expense' && dueDate == null) {
      throw Exception('Data de vencimento é obrigatória');
    }

    if (type == 'income' && receivedDate == null) {
      throw Exception('Data de recebimento é obrigatória');
    }

    final transaction = FinanceTransaction(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      type: type,
      description: trimmedDescription,
      amount: amount,
      dueDate: dueDate,
      receivedDate: receivedDate,
      status: status,
      paidAt: paidAt,
      createdAt: DateTime.now(),
      isInstallment: false,
      installmentGroupId: null,
      installmentNumber: null,
      installmentTotal: null,
      installmentFullAmount: null,
      creditCardId: creditCardId,
    );

    await createTransactionUsecase(transaction);
  }

  Future<void> updateTransaction({
    required String id,
    required String userId,
    required String categoryId,
    required String type,
    required String description,
    required double amount,
    required DateTime? dueDate,
    required DateTime? receivedDate,
    required String status,
    required DateTime? paidAt,
    required DateTime createdAt,
    required bool isInstallment,
    required String? installmentGroupId,
    required int? installmentNumber,
    required int? installmentTotal,
    required double? installmentFullAmount,
    required String? creditCardId,
  }) async {
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception('Descrição é obrigatória');
    }

    if (amount <= 0) {
      throw Exception('Valor deve ser maior que zero');
    }

    final transaction = FinanceTransaction(
      id: id,
      userId: userId,
      categoryId: categoryId,
      type: type,
      description: trimmedDescription,
      amount: amount,
      dueDate: dueDate,
      receivedDate: receivedDate,
      status: status,
      paidAt: paidAt,
      createdAt: createdAt,
      isInstallment: isInstallment,
      installmentGroupId: installmentGroupId,
      installmentNumber: installmentNumber,
      installmentTotal: installmentTotal,
      installmentFullAmount: installmentFullAmount,
      creditCardId: creditCardId,
    );

    await updateTransactionUsecase(transaction);
  }

  Future<void> createExpenseInstallments({
    required String userId,
    required String categoryId,
    required String description,
    required double totalAmount,
    required int installmentCount,
    required DateTime firstDueDate,
    required String? creditCardId,
  }) async {
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception('Descrição é obrigatória');
    }

    if (totalAmount <= 0) {
      throw Exception('Valor total deve ser maior que zero');
    }

    if (installmentCount < 2) {
      throw Exception('Quantidade de parcelas deve ser pelo menos 2');
    }

    final groupId = const Uuid().v4();
    final cents = (totalAmount * 100).round();
    final baseInstallment = cents ~/ installmentCount;
    final remainder = cents % installmentCount;

    for (int i = 0; i < installmentCount; i++) {
      final installmentCents =
          i == installmentCount - 1 ? baseInstallment + remainder : baseInstallment;

      final installmentAmount = installmentCents / 100;
      final dueDate = _addMonths(firstDueDate, i);

      final transaction = FinanceTransaction(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: categoryId,
        type: 'expense',
        description: '$trimmedDescription (${i + 1}/$installmentCount)',
        amount: installmentAmount,
        dueDate: dueDate,
        receivedDate: null,
        status: 'pending',
        paidAt: null,
        createdAt: DateTime.now(),
        isInstallment: true,
        installmentGroupId: groupId,
        installmentNumber: i + 1,
        installmentTotal: installmentCount,
        installmentFullAmount: totalAmount,
        creditCardId: creditCardId,
      );

      await createTransactionUsecase(transaction);
    }
  }

  Future<void> updateStatus({
    required String transactionId,
    required String status,
    required DateTime? paidAt,
  }) async {
    await togglePaidStatusUsecase(
      transactionId: transactionId,
      status: status,
      paidAt: paidAt,
    );
  }

  Future<void> payCreditCardBill({
    required String userId,
    required String creditCardId,
    required DateTime monthReference,
    required DateTime paidAt,
  }) async {
    await createTransactionUsecase.repository.payCreditCardBill(
      userId: userId,
      creditCardId: creditCardId,
      year: monthReference.year,
      month: monthReference.month,
      paidAt: paidAt,
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    await deleteTransactionUsecase(transactionId);
  }

  Future<void> reuseTransactionNextMonth({
    required FinanceTransaction transaction,
    required double amount,
    required DateTime nextDate,
  }) async {
    final duplicated = FinanceTransaction(
      id: const Uuid().v4(),
      userId: transaction.userId,
      categoryId: transaction.categoryId,
      type: transaction.type,
      description: transaction.description,
      amount: amount,
      dueDate: transaction.type == 'expense' ? nextDate : null,
      receivedDate: transaction.type == 'income' ? nextDate : null,
      status: 'pending',
      paidAt: null,
      createdAt: DateTime.now(),
      isInstallment: false,
      installmentGroupId: null,
      installmentNumber: null,
      installmentTotal: null,
      installmentFullAmount: null,
      creditCardId: transaction.creditCardId,
    );

    await createTransactionUsecase(duplicated);
  }

  DateTime suggestedNextMonthDate(FinanceTransaction transaction) {
    final referenceDate = transaction.type == 'expense'
        ? transaction.dueDate
        : transaction.receivedDate;

    if (referenceDate == null) {
      throw Exception('Transação sem data base para reaproveitar');
    }

    return _addMonths(referenceDate, 1);
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    int year = date.year;
    int month = date.month + monthsToAdd;

    while (month > 12) {
      month -= 12;
      year++;
    }

    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final safeDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime(year, month, safeDay);
  }
}