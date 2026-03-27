import 'package:flutter/material.dart';

class CreditCardStatementCard extends StatelessWidget {
  final String cardName;
  final double amount;
  final int itemsCount;
  final bool isPaid;
  final DateTime? paidAt;
  final VoidCallback? onPayBill;

  const CreditCardStatementCard({
    super.key,
    required this.cardName,
    required this.amount,
    required this.itemsCount,
    required this.isPaid,
    required this.paidAt,
    required this.onPayBill,
  });

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = isPaid ? Colors.greenAccent : Colors.orangeAccent;
    final iconBg = isPaid
        ? Colors.greenAccent.withOpacity(0.14)
        : Colors.blueAccent.withOpacity(0.16);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.credit_card),
                ),
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemsCount lançamento(s) vinculado(s)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: badgeColor.withOpacity(0.22),
                    ),
                  ),
                  child: Text(
                    isPaid ? 'Paga' : 'Em aberto',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Fatura do mês',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatCurrency(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            if (isPaid && paidAt != null) ...[
              Text(
                'Paga em ${_formatDate(paidAt!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isPaid ? null : onPayBill,
                icon: Icon(isPaid ? Icons.check_circle_outline : Icons.payment),
                label: Text(isPaid ? 'Fatura já paga' : 'Pagar fatura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}