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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.02),
              (isPaid ? Colors.greenAccent : Colors.blueAccent)
                  .withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.credit_card),
                ),
                const SizedBox(width: 10),
                _StatusBadge(
                  label: isPaid ? 'Paga' : 'Em aberto',
                  isPaid: isPaid,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              cardName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fatura do mês',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$itemsCount lançamento(s) vinculado(s)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            if (isPaid && paidAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Paga em ${_formatDate(paidAt!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isPaid ? null : onPayBill,
                icon: Icon(
                  isPaid ? Icons.check_circle_outline : Icons.payments_outlined,
                ),
                label: Text(isPaid ? 'Fatura já paga' : 'Pagar fatura'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isPaid;

  const _StatusBadge({
    required this.label,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}