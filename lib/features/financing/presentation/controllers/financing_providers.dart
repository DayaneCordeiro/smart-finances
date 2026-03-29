import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../data/datasources/financing_local_datasource.dart';
import '../../data/repositories/financing_repository_impl.dart';
import '../../domain/entities/financing_contract.dart';
import '../../domain/entities/financing_installment.dart';
import '../../domain/entities/financing_summary.dart';
import '../../domain/repositories/financing_repository.dart';
import '../../domain/usecases/create_financing.dart';
import '../../domain/usecases/get_financings_by_user.dart';
import '../../domain/usecases/get_installments_by_financing.dart';
import '../../domain/usecases/update_financing_installment.dart';

final financingAppDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final financingLocalDataSourceProvider =
    Provider<FinancingLocalDataSource>((ref) {
  return FinancingLocalDataSource(ref.read(financingAppDatabaseProvider));
});

final financingRepositoryProvider = Provider<FinancingRepository>((ref) {
  return FinancingRepositoryImpl(ref.read(financingLocalDataSourceProvider));
});

final createFinancingProvider = Provider<CreateFinancing>((ref) {
  return CreateFinancing(ref.read(financingRepositoryProvider));
});

final getFinancingsByUserProvider = Provider<GetFinancingsByUser>((ref) {
  return GetFinancingsByUser(ref.read(financingRepositoryProvider));
});

final getInstallmentsByFinancingProvider =
    Provider<GetInstallmentsByFinancing>((ref) {
  return GetInstallmentsByFinancing(ref.read(financingRepositoryProvider));
});

final updateFinancingInstallmentProvider =
    Provider<UpdateFinancingInstallment>((ref) {
  return UpdateFinancingInstallment(ref.read(financingRepositoryProvider));
});

final financingsProvider =
    FutureProvider.family<List<FinancingContract>, String>((ref, userId) async {
  return ref.read(getFinancingsByUserProvider)(userId);
});

final financingInstallmentsProvider =
    FutureProvider.family<List<FinancingInstallment>, String>(
  (ref, financingId) async {
    return ref.read(getInstallmentsByFinancingProvider)(financingId);
  },
);

final financingSummaryProvider =
    FutureProvider.family<FinancingSummary, String>((ref, financingId) async {
  final installments =
      await ref.read(getInstallmentsByFinancingProvider)(financingId);

  final totalAmount = installments.fold<double>(
    0,
    (sum, installment) => sum + installment.originalAmount,
  );

  final paidAmount = installments.fold<double>(
    0,
    (sum, installment) => sum + (installment.paidAmount ?? 0),
  );

  final totalDiscount = installments.fold<double>(
    0,
    (sum, installment) => sum + installment.discountAmount,
  );

  final paidInstallments = installments.where((i) => i.isPaid).length;
  final remainingInstallments = installments.where((i) => !i.isPaid).length;

  final remainingAmount = installments
      .where((i) => !i.isPaid)
      .fold<double>(
        0,
        (sum, installment) => sum + installment.originalAmount,
      );

  return FinancingSummary(
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    totalDiscount: totalDiscount,
    paidInstallments: paidInstallments,
    remainingInstallments: remainingInstallments,
    remainingAmount: remainingAmount,
  );
});

final financingActionsProvider = Provider<FinancingActions>((ref) {
  return FinancingActions(
    ref: ref,
    createFinancingUseCase: ref.read(createFinancingProvider),
    updateInstallmentUseCase: ref.read(updateFinancingInstallmentProvider),
  );
});

class FinancingActions {
  final Ref ref;
  final CreateFinancing createFinancingUseCase;
  final UpdateFinancingInstallment updateInstallmentUseCase;

  FinancingActions({
    required this.ref,
    required this.createFinancingUseCase,
    required this.updateInstallmentUseCase,
  });

  Future<void> createNewFinancing({
    required String userId,
    required String name,
    required String assetName,
    required String? description,
    required double totalAmount,
    required int totalInstallments,
    required DateTime firstDueDate,
  }) async {
    final trimmedName = name.trim();
    final trimmedAsset = assetName.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Informe o nome do financiamento');
    }

    if (trimmedAsset.isEmpty) {
      throw Exception('Informe o bem financiado');
    }

    if (totalAmount <= 0) {
      throw Exception('Informe um valor total válido');
    }

    if (totalInstallments <= 0) {
      throw Exception('Informe a quantidade de parcelas');
    }

    final contractId = const Uuid().v4();
    final contract = FinancingContract(
      id: contractId,
      userId: userId,
      name: trimmedName,
      assetName: trimmedAsset,
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      totalAmount: totalAmount,
      totalInstallments: totalInstallments,
      firstDueDate: firstDueDate,
      createdAt: DateTime.now(),
    );

    final installmentAmount = totalAmount / totalInstallments;

    final installments = List.generate(totalInstallments, (index) {
      return FinancingInstallment(
        id: const Uuid().v4(),
        financingId: contractId,
        installmentNumber: index + 1,
        originalAmount: installmentAmount,
        paidAmount: null,
        discountAmount: 0,
        dueDate: _addMonths(firstDueDate, index),
        paidAt: null,
        status: 'pending',
      );
    });

    await createFinancingUseCase(
      contract: contract,
      installments: installments,
    );

    for (final installment in installments) {
      await ref
          .read(transactionControllerProvider)
          .createTransactionFromFinancingInstallment(
            userId: userId,
            description: contract.name,
            storeName: contract.assetName,
            amount: installment.originalAmount,
            dueDate: installment.dueDate,
            installmentNumber: installment.installmentNumber,
            installmentTotal: totalInstallments,
            financingId: contract.id,
            financingInstallmentId: installment.id,
          );
    }
  }

  Future<void> createExistingFinancing({
    required String userId,
    required String name,
    required String assetName,
    required String? description,
    required double totalAmount,
    required int totalInstallments,
    required int alreadyPaidInstallments,
    required DateTime firstDueDate,
  }) async {
    final trimmedName = name.trim();
    final trimmedAsset = assetName.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Informe o nome do financiamento');
    }

    if (trimmedAsset.isEmpty) {
      throw Exception('Informe o bem financiado');
    }

    if (totalAmount <= 0) {
      throw Exception('Informe o valor total');
    }

    if (totalInstallments <= 0) {
      throw Exception('Informe a quantidade de parcelas');
    }

    if (alreadyPaidInstallments < 0 ||
        alreadyPaidInstallments > totalInstallments) {
      throw Exception('Quantidade de parcelas pagas inválida');
    }

    final contractId = const Uuid().v4();
    final contract = FinancingContract(
      id: contractId,
      userId: userId,
      name: trimmedName,
      assetName: trimmedAsset,
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      totalAmount: totalAmount,
      totalInstallments: totalInstallments,
      firstDueDate: firstDueDate,
      createdAt: DateTime.now(),
    );

    final installmentAmount = totalAmount / totalInstallments;

    final installments = List.generate(totalInstallments, (index) {
      final number = index + 1;
      final isAlreadyPaid = number <= alreadyPaidInstallments;

      return FinancingInstallment(
        id: const Uuid().v4(),
        financingId: contractId,
        installmentNumber: number,
        originalAmount: installmentAmount,
        paidAmount: isAlreadyPaid ? installmentAmount : null,
        discountAmount: 0,
        dueDate: _addMonths(firstDueDate, index),
        paidAt: isAlreadyPaid ? DateTime.now() : null,
        status: isAlreadyPaid ? 'paid' : 'pending',
      );
    });

    await createFinancingUseCase(
      contract: contract,
      installments: installments,
    );

    for (final installment in installments) {
      await ref
          .read(transactionControllerProvider)
          .createTransactionFromFinancingInstallment(
            userId: userId,
            description: contract.name,
            storeName: contract.assetName,
            amount: installment.originalAmount,
            dueDate: installment.dueDate,
            installmentNumber: installment.installmentNumber,
            installmentTotal: totalInstallments,
            financingId: contract.id,
            financingInstallmentId: installment.id,
            initialStatus: installment.status,
            initialPaidAt: installment.paidAt,
            initialPaidAmount: installment.paidAmount,
            initialDiscountAmount: installment.discountAmount,
          );
    }
  }

  Future<void> payInstallment({
    required FinancingInstallment installment,
    required double paidAmount,
    required DateTime paidAt,
  }) async {
    if (paidAmount <= 0) {
      throw Exception('Informe o valor pago');
    }

    if (paidAmount > installment.originalAmount) {
      throw Exception('O valor pago não pode ser maior que o valor da parcela');
    }

    final calculatedDiscount = installment.originalAmount - paidAmount;

    final updated = FinancingInstallment(
      id: installment.id,
      financingId: installment.financingId,
      installmentNumber: installment.installmentNumber,
      originalAmount: installment.originalAmount,
      paidAmount: paidAmount,
      discountAmount: calculatedDiscount,
      dueDate: installment.dueDate,
      paidAt: paidAt,
      status: 'paid',
    );

    await updateInstallmentUseCase(updated);

    await ref
        .read(transactionRepositoryProvider)
        .updateTransactionByFinancingInstallmentId(
          financingInstallmentId: installment.id,
          status: 'paid',
          paidAt: paidAt,
          paidAmount: paidAmount,
          discountAmount: calculatedDiscount,
        );
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    int year = date.year;
    int month = date.month + monthsToAdd;

    while (month > 12) {
      month -= 12;
      year++;
    }

    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = date.day > lastDay ? lastDay : date.day;

    return DateTime(year, month, safeDay);
  }
}