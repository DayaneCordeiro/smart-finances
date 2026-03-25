import 'package:flutter/material.dart';

import '../../domain/entities/finance_transaction.dart';
import 'transaction_type_badge.dart';

class TransactionListCard extends StatelessWidget {
  final FinanceTransaction transaction;
  final String effectiveStatus;
  final VoidCallback onEdit;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onCopyNextMonth;
  final VoidCallback onDelete;

  const TransactionListCard({
    super.key,
    required this.transaction,
    required this.effectiveStatus,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onCopyNextMonth,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';

    final accentColor = isIncome ? Colors.greenAccent : Colors.orangeAccent;
    final iconData = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.18),
        ),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.015),
            accentColor.withOpacity(0.035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accentColor.withOpacity(0.14),
                    child: Icon(
                      iconData,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              transaction.description,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            TransactionTypeBadge(type: transaction.type),
                            _StatusBadge(status: effectiveStatus),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              _formatCurrency(transaction.amount),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              transaction.type == 'expense'
                                  ? 'Vencimento: ${_formatDate(transaction.dueDate!)}'
                                  : 'Recebimento: ${_formatDate(transaction.receivedDate!)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            if (transaction.isInstallment &&
                                transaction.installmentNumber != null &&
                                transaction.installmentTotal != null)
                              Text(
                                'Parcela ${transaction.installmentNumber}/${transaction.installmentTotal}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            if (transaction.paidAt != null)
                              Text(
                                transaction.type == 'expense'
                                    ? 'Pago em ${_formatDate(transaction.paidAt!)}'
                                    : 'Recebido em ${_formatDate(transaction.paidAt!)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                    if (onChangeStatus != null)
                      OutlinedButton.icon(
                        onPressed: onChangeStatus,
                        icon: const Icon(Icons.published_with_changes, size: 18),
                        label: const Text('Status'),
                      ),
                    if (onCopyNextMonth != null)
                      OutlinedButton.icon(
                        onPressed: onCopyNextMonth,
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copiar'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Excluir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => Colors.greenAccent,
      'received' => Colors.greenAccent,
      'overdue' => Colors.orangeAccent,
      _ => Colors.white70,
    };

    final label = switch (status) {
      'pending' => 'Pendente',
      'paid' => 'Pago',
      'received' => 'Recebido',
      'overdue' => 'Atrasado',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.26)),
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