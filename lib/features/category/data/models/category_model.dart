import '../../domain/entities/app_category.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String type;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory CategoryModel.fromEntity(AppCategory entity) {
    return CategoryModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      createdAt: entity.createdAt,
    );
  }

  AppCategory toEntity() {
    return AppCategory(
      id: id,
      userId: userId,
      name: name,
      type: type,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}