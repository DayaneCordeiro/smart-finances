import '../../domain/entities/financing_contract.dart';

class FinancingContractModel {
  final String id;
  final String userId;
  final String name;
  final String assetName;
  final String? description;
  final double totalAmount;
  final int totalInstallments;
  final DateTime firstDueDate;
  final DateTime createdAt;

  const FinancingContractModel({
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

  factory FinancingContractModel.fromEntity(FinancingContract entity) {
    return FinancingContractModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      assetName: entity.assetName,
      description: entity.description,
      totalAmount: entity.totalAmount,
      totalInstallments: entity.totalInstallments,
      firstDueDate: entity.firstDueDate,
      createdAt: entity.createdAt,
    );
  }

  FinancingContract toEntity() {
    return FinancingContract(
      id: id,
      userId: userId,
      name: name,
      assetName: assetName,
      description: description,
      totalAmount: totalAmount,
      totalInstallments: totalInstallments,
      firstDueDate: firstDueDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'asset_name': assetName,
      'description': description,
      'total_amount': totalAmount,
      'total_installments': totalInstallments,
      'first_due_date': firstDueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FinancingContractModel.fromMap(Map<String, dynamic> map) {
    return FinancingContractModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      assetName: map['asset_name'] as String,
      description: map['description'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      totalInstallments: map['total_installments'] as int,
      firstDueDate: DateTime.parse(map['first_due_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}