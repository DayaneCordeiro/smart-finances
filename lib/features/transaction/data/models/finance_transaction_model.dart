import '../../domain/entities/finance_transaction.dart';

class FinanceTransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String type;
  final String description;
  final double amount;
  final DateTime transactionDate;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  const FinanceTransactionModel({
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

  factory FinanceTransactionModel.fromEntity(FinanceTransaction entity) {
    return FinanceTransactionModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      type: entity.type,
      description: entity.description,
      amount: entity.amount,
      transactionDate: entity.transactionDate,
      isPaid: entity.isPaid,
      paidAt: entity.paidAt,
      createdAt: entity.createdAt,
    );
  }

  FinanceTransaction toEntity() {
    return FinanceTransaction(
      id: id,
      userId: userId,
      categoryId: categoryId,
      type: type,
      description: description,
      amount: amount,
      transactionDate: transactionDate,
      isPaid: isPaid,
      paidAt: paidAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'type': type,
      'description': description,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'is_paid': isPaid ? 1 : 0,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FinanceTransactionModel.fromMap(Map<String, dynamic> map) {
    return FinanceTransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      isPaid: (map['is_paid'] as int) == 1,
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}