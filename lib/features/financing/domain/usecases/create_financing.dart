import '../entities/financing_contract.dart';
import '../entities/financing_installment.dart';
import '../repositories/financing_repository.dart';

class CreateFinancing {
  final FinancingRepository repository;

  CreateFinancing(this.repository);

  Future<void> call({
    required FinancingContract contract,
    required List<FinancingInstallment> installments,
  }) async {
    await repository.createFinancing(contract);
    await repository.createInstallments(installments);
  }
}