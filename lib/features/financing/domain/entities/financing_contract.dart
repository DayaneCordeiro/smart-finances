class FinancingContract {
  final String id;
  final String userId;
  final String name;
  final String assetName;
  final String? description;
  final double totalAmount;
  final int totalInstallments;
  final DateTime firstDueDate;
  final DateTime createdAt;

  const FinancingContract({
    required this.id,
    required this.userId,
    required this.name,
    required this.assetName,
    required this.description,
    required this.totalAmount,
    required this.totalInstallments,
    required this.firstDueDate,
    required this.createdAt,
  });
}