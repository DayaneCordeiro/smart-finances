import '../entities/credit_card_entity.dart';
import '../repositories/credit_card_repository.dart';

class CreateCreditCard {
  final CreditCardRepository repository;

  CreateCreditCard(this.repository);

  Future<void> call(CreditCardEntity card) async {
    await repository.createCard(card);
  }
}