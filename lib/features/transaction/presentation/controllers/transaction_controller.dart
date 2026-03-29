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
    String? storeName,
    required double amount,
    required DateTime? dueDate,
    required DateTime? receivedDate,
    required String status,
    required DateTime? paidAt,
    required String? creditCardId,
  }) async {
    final trimmedDescription = description.trim();
    final trimmedStoreName = storeName?.trim();

    final transaction = FinanceTransaction(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      type: type,
      description: trimmedDescription,
      storeName: trimmedStoreName?.isEmpty == true ? null : trimmedStoreName,
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
      financingId: null,
      financingInstallmentId: null,
      paidAmount: null,
      discountAmount: 0,
    );

    await createTransactionUsecase(transaction);
  }

  Future<void> createTransactionFromFinancingInstallment({
    required String userId,
    required String description,
    required String storeName,
    required double amount,
    required DateTime dueDate,
    required int installmentNumber,
    required int installmentTotal,
    required String financingId,
    required String financingInstallmentId,
    String initialStatus = 'pending',
    DateTime? initialPaidAt,
    double? initialPaidAmount,
    double initialDiscountAmount = 0,
  }) async {
    final transaction = FinanceTransaction(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: 'financing_expense',
      type: 'expense',
      description: description.trim(),
      storeName: storeName.trim().isEmpty ? null : storeName.trim(),
      amount: amount,
      dueDate: dueDate,
      receivedDate: null,
      status: initialStatus,
      paidAt: initialPaidAt,
      createdAt: DateTime.now(),
      isInstallment: true,
      installmentGroupId: financingId,
      installmentNumber: installmentNumber,
      installmentTotal: installmentTotal,
      installmentFullAmount: null,
      creditCardId: null,
      financingId: financingId,
      financingInstallmentId: financingInstallmentId,
      paidAmount: initialPaidAmount,
      discountAmount: initialDiscountAmount,
    );

    await createTransactionUsecase(transaction);
  }

  Future<void> createExpenseInstallments({
    required String userId,
    required String categoryId,
    required String description,
    required String storeName,
    required double totalAmount,
    required int installmentCount,
    required DateTime firstDueDate,
    required String creditCardId,
  }) async {
    final trimmedStoreName = storeName.trim();
    final trimmedDescription = description.trim();

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
        description: trimmedDescription,
        storeName: trimmedStoreName,
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
        financingId: null,
        financingInstallmentId: null,
        paidAmount: null,
        discountAmount: 0,
      );

      await createTransactionUsecase(transaction);
    }
  }

  Future<void> createExistingDebt({
    required String userId,
    required String categoryId,
    required String storeName,
    required String description,
    required double totalAmount,
    required double installmentAmount,
    required int totalInstallments,
    required int paidInstallments,
    required DateTime nextInstallmentDate,
    required String creditCardId,
  }) async {
    final trimmedStoreName = storeName.trim();
    final trimmedDescription = description.trim();

    final groupId = const Uuid().v4();

    for (int i = paidInstallments; i < totalInstallments; i++) {
      final remainingIndex = i - paidInstallments;
      final dueDate = _addMonths(nextInstallmentDate, remainingIndex);

      final transaction = FinanceTransaction(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: categoryId,
        type: 'expense',
        description: trimmedDescription,
        storeName: trimmedStoreName,
        amount: installmentAmount,
        dueDate: dueDate,
        receivedDate: null,
        status: 'pending',
        paidAt: null,
        createdAt: DateTime.now(),
        isInstallment: true,
        installmentGroupId: groupId,
        installmentNumber: i + 1,
        installmentTotal: totalInstallments,
        installmentFullAmount: totalAmount,
        creditCardId: creditCardId,
        financingId: null,
        financingInstallmentId: null,
        paidAmount: null,
        discountAmount: 0,
      );

      await createTransactionUsecase(transaction);
    }
  }

  Future<void> updateTransaction({
    required String id,
    required String userId,
    required String categoryId,
    required String type,
    required String description,
    String? storeName,
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
    required String? financingId,
    required String? financingInstallmentId,
    required double? paidAmount,
    required double discountAmount,
  }) async {
    final transaction = FinanceTransaction(
      id: id,
      userId: userId,
      categoryId: categoryId,
      type: type,
      description: description.trim(),
      storeName: storeName?.trim().isEmpty == true ? null : storeName?.trim(),
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
      financingId: financingId,
      financingInstallmentId: financingInstallmentId,
      paidAmount: paidAmount,
      discountAmount: discountAmount,
    );

    await updateTransactionUsecase(transaction);
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

  Future<void> deleteTransaction(String transactionId) async {
    await deleteTransactionUsecase(transactionId);
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
      storeName: transaction.storeName,
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
      financingId: null,
      financingInstallmentId: null,
      paidAmount: null,
      discountAmount: 0,
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
    final safeDay =
        date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime(year, month, safeDay);
  }
}