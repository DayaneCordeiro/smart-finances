import 'package:uuid/uuid.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/toggle_transaction_paid_status.dart';

class TransactionController {
  final CreateTransaction createTransactionUsecase;
  final ToggleTransactionPaidStatus togglePaidStatusUsecase;
  final DeleteTransaction deleteTransactionUsecase;

  TransactionController({
    required this.createTransactionUsecase,
    required this.togglePaidStatusUsecase,
    required this.deleteTransactionUsecase,
  });

  Future<void> createTransaction({
    required String userId,
    required String categoryId,
    required String type,
    required String description,
    required double amount,
    required DateTime transactionDate,
    required bool isPaid,
  }) async {
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception('Descrição é obrigatória');
    }

    if (amount <= 0) {
      throw Exception('Valor deve ser maior que zero');
    }

    final transaction = FinanceTransaction(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      type: type,
      description: trimmedDescription,
      amount: amount,
      transactionDate: transactionDate,
      isPaid: isPaid,
      paidAt: isPaid ? DateTime.now() : null,
      createdAt: DateTime.now(),
    );

    await createTransactionUsecase(transaction);
  }

  Future<void> togglePaidStatus({
    required String transactionId,
    required bool isPaid,
  }) async {
    await togglePaidStatusUsecase(
      transactionId: transactionId,
      isPaid: isPaid,
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    await deleteTransactionUsecase(transactionId);
  }
}