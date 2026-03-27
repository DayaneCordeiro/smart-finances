import '../entities/credit_card_entity.dart';

abstract class CreditCardRepository {
  Future<void> createCreditCard(CreditCardEntity card);
  Future<void> updateCreditCard(CreditCardEntity card);
  Future<void> deleteCreditCard(String cardId);
  Future<bool> hasTransactionsLinkedToCard(String cardId);
  Future<List<CreditCardEntity>> getCreditCardsByUser(String userId);
}