class CreditCardEntity {
  final String id;
  final String userId;
  final String name;
  final int closingDay;
  final int dueDay;
  final DateTime createdAt;

  const CreditCardEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.closingDay,
    required this.dueDay,
    required this.createdAt,
  });
}