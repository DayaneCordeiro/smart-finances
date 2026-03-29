class FinancingInstallment {
  final String id;
  final String financingId;
  final int installmentNumber;
  final double originalAmount;
  final double? paidAmount;
  final double discountAmount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String status;

  const FinancingInstallment({
    required this.id,
    required this.financingId,
    required this.installmentNumber,
    required this.originalAmount,
    required this.paidAmount,
    required this.discountAmount,
    required this.dueDate,
    required this.paidAt,
    required this.status,
  });

  bool get isPaid => status == 'paid';
}