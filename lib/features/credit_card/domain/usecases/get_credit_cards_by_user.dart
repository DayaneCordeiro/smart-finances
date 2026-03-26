import '../entities/credit_card_entity.dart';
import '../repositories/credit_card_repository.dart';

class GetCreditCardsByUser {
  final CreditCardRepository repository;

  GetCreditCardsByUser(this.repository);

  Future<List<CreditCardEntity>> call(String userId) async {
    return repository.getCardsByUser(userId);
  }
}