import '../entities/credit_card_entity.dart';
import '../repositories/credit_card_repository.dart';

class UpdateCreditCard {
  final CreditCardRepository repository;

  UpdateCreditCard(this.repository);

  Future<void> call(CreditCardEntity card) {
    return repository.updateCreditCard(card);
  }
}