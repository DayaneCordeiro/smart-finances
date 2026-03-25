class FinanceTransaction {
  final String id;
  final String userId;
  final String categoryId;
  final String type; // income | expense
  final String description;
  final double amount;
  final DateTime? dueDate;
  final DateTime? receivedDate;
  final String status; // pending | paid | received | overdue
  final DateTime? paidAt;
  final DateTime createdAt;

  final bool isInstallment;
  final String? installmentGroupId;
  final int? installmentNumber;
  final int? installmentTotal;
  final double? installmentFullAmount;

  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.receivedDate,
    required this.status,
    required this.paidAt,
    required this.createdAt,
    required this.isInstallment,
    required this.installmentGroupId,
    required this.installmentNumber,
    required this.installmentTotal,
    required this.installmentFullAmount,
  });
}