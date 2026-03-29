import '../entities/financing_installment.dart';
import '../repositories/financing_repository.dart';

class UpdateFinancingInstallment {
  final FinancingRepository repository;

  UpdateFinancingInstallment(this.repository);

  Future<void> call(FinancingInstallment installment) {
    return repository.updateInstallment(installment);
  }
}