class FinanceTransaction {
  final String id;
  final String userId;
  final String categoryId;
  final String type; // income | expense
  final String description;
  final double amount;
  final DateTime transactionDate;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.description,
    required this.amount,
    required this.transactionDate,
    required this.isPaid,
    required this.paidAt,
    required this.createdAt,
  });
}