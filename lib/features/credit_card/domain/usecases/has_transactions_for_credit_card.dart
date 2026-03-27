import '../repositories/credit_card_repository.dart';

class HasTransactionsForCreditCard {
  final CreditCardRepository repository;

  HasTransactionsForCreditCard(this.repository);

  Future<bool> call(String cardId) {
    return repository.hasTransactionsLinkedToCard(cardId);
  }
}