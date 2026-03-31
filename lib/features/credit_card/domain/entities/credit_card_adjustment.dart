class CreditCardAdjustment {
  final String id;
  final String userId;
  final String creditCardId;
  final String type; // refund | manual_adjustment
  final double amount;
  final double remainingAmount;
  final DateTime adjustmentDate;
  final String description;
  final String? relatedTransactionId;
  final DateTime createdAt;

  const CreditCardAdjustment({
    required this.id,
    required this.userId,
    required this.creditCardId,
    required this.type,
    required this.amount,
    double? remainingAmount,
    required this.adjustmentDate,
    required this.description,
    required this.createdAt,
    this.relatedTransactionId,
  }) : remainingAmount = remainingAmount ?? amount;

  CreditCardAdjustment copyWith({
    String? id,
    String? userId,
    String? creditCardId,
    String? type,
    double? amount,
    double? remainingAmount,
    DateTime? adjustmentDate,
    String? description,
    String? relatedTransactionId,
    DateTime? createdAt,
  }) {
    return CreditCardAdjustment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      creditCardId: creditCardId ?? this.creditCardId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      adjustmentDate: adjustmentDate ?? this.adjustmentDate,
      description: description ?? this.description,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}