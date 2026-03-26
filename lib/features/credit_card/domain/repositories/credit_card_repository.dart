import '../entities/credit_card_entity.dart';

abstract class CreditCardRepository {
  Future<void> createCard(CreditCardEntity card);
  Future<List<CreditCardEntity>> getCardsByUser(String userId);
}