import '../../domain/entities/financing_contract.dart';
import '../../domain/entities/financing_installment.dart';
import '../../domain/repositories/financing_repository.dart';
import '../datasources/financing_local_datasource.dart';
import '../models/financing_contract_model.dart';
import '../models/financing_installment_model.dart';

class FinancingRepositoryImpl implements FinancingRepository {
  final FinancingLocalDataSource localDataSource;

  FinancingRepositoryImpl(this.localDataSource);

  @override
  Future<void> createFinancing(FinancingContract contract) {
    return localDataSource.createFinancing(
      FinancingContractModel.fromEntity(contract),
    );
  }

  @override
  Future<void> createInstallments(List<FinancingInstallment> installments) {
    return localDataSource.createInstallments(
      installments.map(FinancingInstallmentModel.fromEntity).toList(),
    );
  }

  @override
  Future<List<FinancingContract>> getFinancingsByUser(String userId) async {
    final result = await localDataSource.getFinancingsByUser(userId);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<FinancingInstallment>> getInstallmentsByFinancing(
    String financingId,
  ) async {
    final result = await localDataSource.getInstallmentsByFinancing(financingId);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> updateInstallment(FinancingInstallment installment) {
    return localDataSource.updateInstallment(
      FinancingInstallmentModel.fromEntity(installment),
    );
  }
}