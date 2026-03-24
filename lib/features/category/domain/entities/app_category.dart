class AppCategory {
  final String id;
  final String userId;
  final String name;
  final String type; // income | expense
  final DateTime createdAt;

  const AppCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.createdAt,
  });
}