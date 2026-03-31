import 'package:flutter/material.dart';

class CreditCardStatementCard extends StatelessWidget {
  final String cardName;
  final double amount;
  final int itemsCount;
  final bool isPaid;
  final DateTime? paidAt;
  final VoidCallback? onPayBill;
  final VoidCallback? onOpenDetails;

  const CreditCardStatementCard({
    super.key,
    required this.cardName,
    required this.amount,
    required this.itemsCount,
    required this.isPaid,
    required this.paidAt,
    required this.onPayBill,
    required this.onOpenDetails,
  });

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return isNegative ? '-R\$ $formatted' : 'R\$ $formatted';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final hasCredit = amount < 0;
    final noPaymentNeeded = amount <= 0;

    final badgeColor = hasCredit
        ? Colors.lightBlueAccent
        : isPaid
            ? Colors.greenAccent
            : Colors.orangeAccent;

    final badgeText = hasCredit
        ? 'Crédito disponível'
        : isPaid
            ? 'Paga'
            : 'Em aberto';

    final iconBg = hasCredit
        ? Colors.lightBlueAccent.withOpacity(0.14)
        : isPaid
            ? Colors.greenAccent.withOpacity(0.14)
            : Colors.blueAccent.withOpacity(0.16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenDetails,
        child: Card(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$itemsCount lançamento(s) do mês',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        badgeText,
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
                  hasCredit ? 'Crédito acumulado' : 'Fatura do mês',
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
                if (!hasCredit && isPaid && paidAt != null) ...[
                  Text(
                    'Paga em ${_formatDate(paidAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasCredit) ...[
                  Text(
                    'Esse valor será abatido na próxima fatura.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenDetails,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Ver compras'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: noPaymentNeeded ? null : onPayBill,
                        icon: Icon(
                          noPaymentNeeded
                              ? Icons.check_circle_outline
                              : Icons.payment,
                        ),
                        label: Text(
                          noPaymentNeeded ? 'Sem pagamento' : 'Pagar fatura',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}