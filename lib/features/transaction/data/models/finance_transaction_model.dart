import '../../domain/entities/finance_transaction.dart';

class FinanceTransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String type;
  final String description;
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

  const FinanceTransactionModel({
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

  factory FinanceTransactionModel.fromEntity(FinanceTransaction entity) {
    return FinanceTransactionModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      type: entity.type,
      description: entity.description,
      amount: entity.amount,
      dueDate: entity.dueDate,
      receivedDate: entity.receivedDate,
      status: entity.status,
      paidAt: entity.paidAt,
      createdAt: entity.createdAt,
      isInstallment: entity.isInstallment,
      installmentGroupId: entity.installmentGroupId,
      installmentNumber: entity.installmentNumber,
      installmentTotal: entity.installmentTotal,
      installmentFullAmount: entity.installmentFullAmount,
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
      dueDate: dueDate,
      receivedDate: receivedDate,
      status: status,
      paidAt: paidAt,
      createdAt: createdAt,
      isInstallment: isInstallment,
      installmentGroupId: installmentGroupId,
      installmentNumber: installmentNumber,
      installmentTotal: installmentTotal,
      installmentFullAmount: installmentFullAmount,
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
      'due_date': dueDate?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(),
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_installment': isInstallment ? 1 : 0,
      'installment_group_id': installmentGroupId,
      'installment_number': installmentNumber,
      'installment_total': installmentTotal,
      'installment_full_amount': installmentFullAmount,
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
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      receivedDate: map['received_date'] != null
          ? DateTime.parse(map['received_date'] as String)
          : null,
      status: map['status'] as String,
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      isInstallment: ((map['is_installment'] ?? 0) as int) == 1,
      installmentGroupId: map['installment_group_id'] as String?,
      installmentNumber: map['installment_number'] as int?,
      installmentTotal: map['installment_total'] as int?,
      installmentFullAmount: map['installment_full_amount'] != null
          ? (map['installment_full_amount'] as num).toDouble()
          : null,
    );
  }
}