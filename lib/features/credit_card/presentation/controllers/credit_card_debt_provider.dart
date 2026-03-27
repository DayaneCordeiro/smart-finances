import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transaction/domain/entities/finance_transaction.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../domain/entities/credit_card_debt.dart';

final creditCardDebtsProvider =
    FutureProvider.family<List<CreditCardDebt>, String>((ref, userId) async {
  final transactions = await ref.watch(transactionsProvider(userId).future);

  final grouped = <String, List<FinanceTransaction>>{};

  for (final transaction in transactions) {
    final hasDebtData = transaction.isInstallment &&
        transaction.installmentGroupId != null &&
        transaction.creditCardId != null;

    if (!hasDebtData) continue;

    final groupId = transaction.installmentGroupId!;
    grouped.putIfAbsent(groupId, () => []).add(transaction);
  }

  final debts = <CreditCardDebt>[];

  for (final entry in grouped.entries) {
    final list = entry.value;
    if (list.isEmpty) continue;

    list.sort((a, b) {
      final aNumber = a.installmentNumber ?? 0;
      final bNumber = b.installmentNumber ?? 0;
      return aNumber.compareTo(bNumber);
    });

    final first = list.first;
    final paidInstallments = list.where((t) => t.status == 'paid').length;
    final totalInstallments = first.installmentTotal ?? list.length;
    final totalAmount =
        first.installmentFullAmount ??
        list.fold<double>(0, (sum, t) => sum + t.amount);

    debts.add(
      CreditCardDebt(
        id: entry.key,
        userId: first.userId,
        cardId: first.creditCardId!,
        store: (first.storeName ?? '').trim(),
        description: first.description.trim(),
        totalAmount: totalAmount,
        totalInstallments: totalInstallments,
        installmentAmount: first.amount,
        paidInstallments: paidInstallments,
      ),
    );
  }

  debts.sort(
    (a, b) => a.description.toLowerCase().compareTo(
          b.description.toLowerCase(),
        ),
  );

  return debts.where((debt) => debt.remainingInstallments > 0).toList();
});