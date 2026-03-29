class FinanceTransaction {
  final String id;
  final String userId;
  final String categoryId;
  final String type;
  final String description;
  final String? storeName;
  final double amount;
  final DateTime? dueDate;
  final DateTime? receivedDate;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  final bool isInstallment;
  final String? installmentGroupId;
  final int? installmentNumber;
  final int? installmentTotal;
  final double? installmentFullAmount;
  final String? creditCardId;

  final String? financingId;
  final String? financingInstallmentId;
  final double? paidAmount;
  final double discountAmount;

  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.description,
    required this.storeName,
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
    required this.creditCardId,
    required this.financingId,
    required this.financingInstallmentId,
    required this.paidAmount,
    required this.discountAmount,
  });

  bool get isFinancingInstallment =>
      financingId != null && financingInstallmentId != null;
}