import 'package:flutter/material.dart';

import '../../domain/entities/finance_transaction.dart';
import 'transaction_type_badge.dart';

class TransactionListCard extends StatelessWidget {
  final FinanceTransaction transaction;
  final String effectiveStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onCopyNextMonth;
  final VoidCallback? onDelete;

  const TransactionListCard({
    super.key,
    required this.transaction,
    required this.effectiveStatus,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onCopyNextMonth,
    required this.onDelete,
  });

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Pago';
      case 'received':
        return 'Recebido';
      case 'overdue':
        return 'Atrasado';
      default:
        return 'Pendente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'received':
        return Colors.greenAccent;
      case 'overdue':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];

    if (transaction.storeName != null && transaction.storeName!.trim().isNotEmpty) {
      subtitleParts.add(transaction.storeName!.trim());
    }

    if (transaction.installmentNumber != null &&
        transaction.installmentTotal != null) {
      subtitleParts.add(
        '${transaction.installmentNumber}/${transaction.installmentTotal}',
      );
    }

    final subtitle = subtitleParts.join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: Icon(
                    transaction.type == 'income'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TransactionTypeBadge(type: transaction.type),
                          Text(
                            _statusLabel(effectiveStatus),
                            style: TextStyle(
                              color: _statusColor(effectiveStatus),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(transaction.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (transaction.paidAmount != null &&
                        transaction.paidAmount != transaction.amount) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Pago: ${_formatCurrency(transaction.paidAmount!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                    if (transaction.discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Desconto: ${_formatCurrency(transaction.discountAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.greenAccent,
                            ),
                      ),
                    ],
                    if (transaction.type == 'expense' &&
                        transaction.dueDate != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(transaction.dueDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                    if (transaction.type == 'income' &&
                        transaction.receivedDate != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(transaction.receivedDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onEdit != null)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                if (onChangeStatus != null)
                  OutlinedButton.icon(
                    onPressed: onChangeStatus,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Status'),
                  ),
                if (onCopyNextMonth != null)
                  OutlinedButton.icon(
                    onPressed: onCopyNextMonth,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar'),
                  ),
                if (onDelete != null)
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}