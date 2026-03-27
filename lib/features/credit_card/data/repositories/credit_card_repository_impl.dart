import '../../domain/entities/credit_card_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';
import '../datasources/credit_card_local_datasource.dart';
import '../models/credit_card_model.dart';

class CreditCardRepositoryImpl implements CreditCardRepository {
  final CreditCardLocalDataSource localDataSource;

  CreditCardRepositoryImpl(this.localDataSource);

  @override
  Future<void> createCreditCard(CreditCardEntity card) async {
    await localDataSource.createCreditCard(
      CreditCardModel.fromEntity(card),
    );
  }

  @override
  Future<void> updateCreditCard(CreditCardEntity card) async {
    await localDataSource.updateCreditCard(
      CreditCardModel.fromEntity(card),
    );
  }

  @override
  Future<void> deleteCreditCard(String cardId) async {
    await localDataSource.deleteCreditCard(cardId);
  }

  @override
  Future<bool> hasTransactionsLinkedToCard(String cardId) {
    return localDataSource.hasTransactionsLinkedToCard(cardId);
  }

  @override
  Future<List<CreditCardEntity>> getCreditCardsByUser(String userId) async {
    final cards = await localDataSource.getCreditCardsByUser(userId);
    return cards.map((card) => card.toEntity()).toList();
  }
}