import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/credit_card_local_datasource.dart';
import '../../data/repositories/credit_card_repository_impl.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';
import '../../domain/usecases/create_credit_card.dart';
import '../../domain/usecases/delete_credit_card.dart';
import '../../domain/usecases/get_credit_cards_by_user.dart';
import '../../domain/usecases/has_transactions_for_credit_card.dart';
import '../../domain/usecases/update_credit_card.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final creditCardLocalDataSourceProvider =
    Provider<CreditCardLocalDataSource>((ref) {
  return CreditCardLocalDataSource(ref.read(appDatabaseProvider));
});

final creditCardRepositoryProvider = Provider<CreditCardRepository>((ref) {
  return CreditCardRepositoryImpl(ref.read(creditCardLocalDataSourceProvider));
});

final createCreditCardProvider = Provider<CreateCreditCard>((ref) {
  return CreateCreditCard(ref.read(creditCardRepositoryProvider));
});

final updateCreditCardProvider = Provider<UpdateCreditCard>((ref) {
  return UpdateCreditCard(ref.read(creditCardRepositoryProvider));
});

final deleteCreditCardProvider = Provider<DeleteCreditCard>((ref) {
  return DeleteCreditCard(ref.read(creditCardRepositoryProvider));
});

final hasTransactionsForCreditCardProvider =
    Provider<HasTransactionsForCreditCard>((ref) {
  return HasTransactionsForCreditCard(ref.read(creditCardRepositoryProvider));
});

final getCreditCardsByUserProvider = Provider<GetCreditCardsByUser>((ref) {
  return GetCreditCardsByUser(ref.read(creditCardRepositoryProvider));
});

final creditCardsProvider =
    FutureProvider.family<List<CreditCardEntity>, String>((ref, userId) async {
  final useCase = ref.read(getCreditCardsByUserProvider);
  return useCase(userId);
});

final creditCardActionsProvider = Provider<CreditCardActions>((ref) {
  return CreditCardActions(
    createCreditCardUseCase: ref.read(createCreditCardProvider),
    updateCreditCardUseCase: ref.read(updateCreditCardProvider),
    deleteCreditCardUseCase: ref.read(deleteCreditCardProvider),
    hasTransactionsForCreditCardUseCase:
        ref.read(hasTransactionsForCreditCardProvider),
  );
});

class CreditCardActions {
  final CreateCreditCard createCreditCardUseCase;
  final UpdateCreditCard updateCreditCardUseCase;
  final DeleteCreditCard deleteCreditCardUseCase;
  final HasTransactionsForCreditCard hasTransactionsForCreditCardUseCase;

  CreditCardActions({
    required this.createCreditCardUseCase,
    required this.updateCreditCardUseCase,
    required this.deleteCreditCardUseCase,
    required this.hasTransactionsForCreditCardUseCase,
  });

  Future<void> create({
    required String userId,
    required String name,
    required int closingDay,
    required int dueDay,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nome do cartão é obrigatório');
    }

    if (closingDay < 1 || closingDay > 31) {
      throw Exception('Dia de fechamento inválido');
    }

    if (dueDay < 1 || dueDay > 31) {
      throw Exception('Dia de vencimento inválido');
    }

    final card = CreditCardEntity(
      id: const Uuid().v4(),
      userId: userId,
      name: trimmedName,
      closingDay: closingDay,
      dueDay: dueDay,
      createdAt: DateTime.now(),
    );

    await createCreditCardUseCase(card);
  }

  Future<void> update({
    required CreditCardEntity card,
    required String name,
    required int closingDay,
    required int dueDay,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nome do cartão é obrigatório');
    }

    if (closingDay < 1 || closingDay > 31) {
      throw Exception('Dia de fechamento inválido');
    }

    if (dueDay < 1 || dueDay > 31) {
      throw Exception('Dia de vencimento inválido');
    }

    final updated = CreditCardEntity(
      id: card.id,
      userId: card.userId,
      name: trimmedName,
      closingDay: closingDay,
      dueDay: dueDay,
      createdAt: card.createdAt,
    );

    await updateCreditCardUseCase(updated);
  }

  Future<void> delete(String cardId) async {
    final hasTransactions =
        await hasTransactionsForCreditCardUseCase(cardId);

    if (hasTransactions) {
      throw Exception(
        'Este cartão possui compras vinculadas e não pode ser excluído.',
      );
    }

    await deleteCreditCardUseCase(cardId);
  }
}