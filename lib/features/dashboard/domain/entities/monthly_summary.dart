class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double paidOrReceivedTotal;
  final double pendingTotal;
  final int overdueCount;
  final double balance;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.paidOrReceivedTotal,
    required this.pendingTotal,
    required this.overdueCount,
    required this.balance,
  });
}