import '../../domain/entities/credit_card_entity.dart';

class CreditCardModel {
  final String id;
  final String userId;
  final String name;
  final int closingDay;
  final int dueDay;
  final DateTime createdAt;

  const CreditCardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.closingDay,
    required this.dueDay,
    required this.createdAt,
  });

  factory CreditCardModel.fromEntity(CreditCardEntity entity) {
    return CreditCardModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      closingDay: entity.closingDay,
      dueDay: entity.dueDay,
      createdAt: entity.createdAt,
    );
  }

  CreditCardEntity toEntity() {
    return CreditCardEntity(
      id: id,
      userId: userId,
      name: name,
      closingDay: closingDay,
      dueDay: dueDay,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'closing_day': closingDay,
      'due_day': dueDay,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CreditCardModel.fromMap(Map<String, dynamic> map) {
    return CreditCardModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      closingDay: map['closing_day'] as int,
      dueDay: map['due_day'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}