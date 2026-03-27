import '../repositories/credit_card_repository.dart';

class DeleteCreditCard {
  final CreditCardRepository repository;

  DeleteCreditCard(this.repository);

  Future<void> call(String cardId) {
    return repository.deleteCreditCard(cardId);
  }
}