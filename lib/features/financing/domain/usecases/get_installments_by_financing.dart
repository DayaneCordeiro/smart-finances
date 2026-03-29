import '../entities/financing_installment.dart';
import '../repositories/financing_repository.dart';

class GetInstallmentsByFinancing {
  final FinancingRepository repository;

  GetInstallmentsByFinancing(this.repository);

  Future<List<FinancingInstallment>> call(String financingId) {
    return repository.getInstallmentsByFinancing(financingId);
  }
}