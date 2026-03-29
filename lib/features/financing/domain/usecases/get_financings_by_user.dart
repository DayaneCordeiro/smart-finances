import '../entities/financing_contract.dart';
import '../repositories/financing_repository.dart';

class GetFinancingsByUser {
  final FinancingRepository repository;

  GetFinancingsByUser(this.repository);

  Future<List<FinancingContract>> call(String userId) {
    return repository.getFinancingsByUser(userId);
  }
}