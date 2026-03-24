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
    required DateTime? dueDate,
    required DateTime? receivedDate,
    required String status,
    required DateTime? paidAt,
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
    );

    await createTransactionUsecase(transaction);
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
}