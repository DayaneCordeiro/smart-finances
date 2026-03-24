class AppUser {
  final String id;
  final String name;
  final String? email;
  final String? password;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.password,
    required this.isActive,
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}