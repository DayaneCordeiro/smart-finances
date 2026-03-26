import '../../domain/entities/credit_card_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';
import '../datasources/credit_card_local_datasource.dart';
import '../models/credit_card_model.dart';

class CreditCardRepositoryImpl implements CreditCardRepository {
  final CreditCardLocalDatasource localDatasource;

  CreditCardRepositoryImpl(this.localDatasource);

  @override
  Future<void> createCard(CreditCardEntity card) async {
    await localDatasource.createCard(CreditCardModel.fromEntity(card));
  }

  @override
  Future<List<CreditCardEntity>> getCardsByUser(String userId) async {
    final items = await localDatasource.getCardsByUser(userId);
    return items.map((e) => e.toEntity()).toList();
  }
}