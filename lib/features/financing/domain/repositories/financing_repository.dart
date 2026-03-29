import '../entities/financing_contract.dart';
import '../entities/financing_installment.dart';

abstract class FinancingRepository {
  Future<void> createFinancing(FinancingContract contract);
  Future<void> createInstallments(List<FinancingInstallment> installments);
  Future<List<FinancingContract>> getFinancingsByUser(String userId);
  Future<List<FinancingInstallment>> getInstallmentsByFinancing(
    String financingId,
  );
  Future<void> updateInstallment(FinancingInstallment installment);
}