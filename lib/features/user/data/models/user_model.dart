import '../../domain/entities/app_user.dart';

class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? password;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.password,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromEntity(AppUser entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      password: entity.password,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      name: name,
      email: email,
      password: password,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      password: map['password'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}