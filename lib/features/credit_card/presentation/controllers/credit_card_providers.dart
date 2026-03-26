import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../../data/datasources/credit_card_local_datasource.dart';
import '../../data/repositories/credit_card_repository_impl.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/usecases/create_credit_card.dart';
import '../../domain/usecases/get_credit_cards_by_user.dart';

final creditCardLocalDatasourceProvider =
    Provider<CreditCardLocalDatasource>((ref) {
  return CreditCardLocalDatasource(ref.read(appDatabaseProvider));
});

final creditCardRepositoryProvider = Provider<CreditCardRepositoryImpl>((ref) {
  return CreditCardRepositoryImpl(ref.read(creditCardLocalDatasourceProvider));
});

final createCreditCardProvider = Provider<CreateCreditCard>((ref) {
  return CreateCreditCard(ref.read(creditCardRepositoryProvider));
});

final getCreditCardsByUserProvider = Provider<GetCreditCardsByUser>((ref) {
  return GetCreditCardsByUser(ref.read(creditCardRepositoryProvider));
});

final creditCardsProvider =
    FutureProvider.family<List<CreditCardEntity>, String>((ref, userId) async {
  return ref.read(getCreditCardsByUserProvider).call(userId);
});

final creditCardControllerProvider = Provider<CreditCardController>((ref) {
  return CreditCardController(
    createCreditCardUsecase: ref.read(createCreditCardProvider),
  );
});

class CreditCardController {
  final CreateCreditCard createCreditCardUsecase;

  CreditCardController({
    required this.createCreditCardUsecase,
  });

  Future<void> createCard({
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

    await createCreditCardUsecase(card);
  }
}