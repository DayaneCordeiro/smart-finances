import '../../domain/entities/financing_installment.dart';

class FinancingInstallmentModel {
  final String id;
  final String financingId;
  final int installmentNumber;
  final double originalAmount;
  final double? paidAmount;
  final double discountAmount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String status;

  const FinancingInstallmentModel({
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

  factory FinancingInstallmentModel.fromEntity(FinancingInstallment entity) {
    return FinancingInstallmentModel(
      id: entity.id,
      financingId: entity.financingId,
      installmentNumber: entity.installmentNumber,
      originalAmount: entity.originalAmount,
      paidAmount: entity.paidAmount,
      discountAmount: entity.discountAmount,
      dueDate: entity.dueDate,
      paidAt: entity.paidAt,
      status: entity.status,
    );
  }

  FinancingInstallment toEntity() {
    return FinancingInstallment(
      id: id,
      financingId: financingId,
      installmentNumber: installmentNumber,
      originalAmount: originalAmount,
      paidAmount: paidAmount,
      discountAmount: discountAmount,
      dueDate: dueDate,
      paidAt: paidAt,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'financing_id': financingId,
      'installment_number': installmentNumber,
      'original_amount': originalAmount,
      'paid_amount': paidAmount,
      'discount_amount': discountAmount,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'status': status,
    };
  }

  factory FinancingInstallmentModel.fromMap(Map<String, dynamic> map) {
    return FinancingInstallmentModel(
      id: map['id'] as String,
      financingId: map['financing_id'] as String,
      installmentNumber: map['installment_number'] as int,
      originalAmount: (map['original_amount'] as num).toDouble(),
      paidAmount: map['paid_amount'] != null
          ? (map['paid_amount'] as num).toDouble()
          : null,
      discountAmount: (map['discount_amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      status: map['status'] as String,
    );
  }
}