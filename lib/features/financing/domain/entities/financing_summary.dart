class FinancingSummary {
  final double totalAmount;
  final double paidAmount;
  final double totalDiscount;
  final int paidInstallments;
  final int remainingInstallments;
  final double remainingAmount;

  const FinancingSummary({
    required this.totalAmount,
    required this.paidAmount,
    required this.totalDiscount,
    required this.paidInstallments,
    required this.remainingInstallments,
    required this.remainingAmount,
  });
}