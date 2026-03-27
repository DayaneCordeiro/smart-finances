class CreditCardDebt {
  final String id;
  final String userId;
  final String cardId;
  final String store;
  final String description;
  final double totalAmount;
  final int totalInstallments;
  final double installmentAmount;
  final int paidInstallments;

  CreditCardDebt({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.store,
    required this.description,
    required this.totalAmount,
    required this.totalInstallments,
    required this.installmentAmount,
    required this.paidInstallments,
  });

  int get remainingInstallments => totalInstallments - paidInstallments;

  double get remainingAmount =>
      remainingInstallments * installmentAmount;
}