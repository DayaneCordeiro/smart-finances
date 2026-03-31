import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../credit_card/domain/entities/credit_card_adjustment.dart';
import '../../../credit_card/presentation/controllers/credit_card_adjustment_providers.dart';
import '../../../credit_card/presentation/controllers/credit_card_debt_provider.dart';
import '../../../dashboard/presentation/controllers/dashboard_providers.dart'
    as dash;
import '../../../financing/domain/entities/financing_installment.dart';
import '../../../financing/presentation/controllers/financing_providers.dart';
import '../../domain/entities/finance_transaction.dart';
import '../controllers/transaction_providers.dart' as tx;
import 'transaction_type_badge.dart';

class TransactionListCard extends ConsumerWidget {
  final FinanceTransaction transaction;
  final String effectiveStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionListCard({
    super.key,
    required this.transaction,
    required this.effectiveStatus,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isPaid =>
      effectiveStatus == 'paid' || effectiveStatus == 'received';

  bool get _isExpense => transaction.type == 'expense';

  bool get _isFinancing => transaction.financingInstallmentId != null;

  bool get _canRefundCreditCardPurchase =>
      _isExpense &&
      transaction.isInstallment &&
      transaction.creditCardId != null &&
      !_isFinancing &&
      transaction.amount > 0;

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return isNegative ? '-R\$ $formatted' : 'R\$ $formatted';
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

  Future<void> _handlePay(BuildContext context, WidgetRef ref) async {
    if (_isFinancing) {
      final result = await showDialog<_FinancingPayDialogResult>(
        context: context,
        builder: (_) => _FinancingPayDialog(
          originalAmount: transaction.amount,
        ),
      );

      if (result == null) return;

      try {
        await ref.read(financingActionsProvider).payInstallment(
              installment: FinancingInstallment(
                id: transaction.financingInstallmentId!,
                financingId: transaction.financingId!,
                installmentNumber: transaction.installmentNumber ?? 1,
                originalAmount: transaction.amount,
                paidAmount: null,
                discountAmount: 0,
                dueDate: transaction.dueDate!,
                paidAt: null,
                status: 'pending',
              ),
              paidAmount: result.paidAmount,
              paidAt: result.paidAt,
            );

        ref.invalidate(tx.transactionsProvider(transaction.userId));
        ref.invalidate(
          dash.filteredTransactionsByMonthProvider(transaction.userId),
        );
        ref.invalidate(dash.monthlySummaryProvider(transaction.userId));
        ref.invalidate(dash.dashboardActiveUserSummaryProvider);
        ref.invalidate(dash.creditCardStatementsProvider(transaction.userId));
        ref.invalidate(financingInstallmentsProvider(transaction.financingId!));
        ref.invalidate(financingSummaryProvider(transaction.financingId!));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento do financiamento registrado com sucesso'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao registrar pagamento: $e')),
          );
        }
      }

      return;
    }

    final result = await showDialog<_SimplePayDialogResult>(
      context: context,
      builder: (_) => const _SimplePayDialog(),
    );

    if (result == null) return;

    try {
      await ref.read(tx.transactionControllerProvider).updateStatus(
            transactionId: transaction.id,
            status: 'paid',
            paidAt: result.paidAt,
          );

      ref.invalidate(tx.transactionsProvider(transaction.userId));
      ref.invalidate(
        dash.filteredTransactionsByMonthProvider(transaction.userId),
      );
      ref.invalidate(dash.monthlySummaryProvider(transaction.userId));
      ref.invalidate(dash.dashboardActiveUserSummaryProvider);
      ref.invalidate(dash.creditCardStatementsProvider(transaction.userId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação marcada como paga')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar pagamento: $e')),
        );
      }
    }
  }

  Future<void> _handleRefund(BuildContext context, WidgetRef ref) async {
    final defaultRefundAmount =
        transaction.installmentFullAmount ?? transaction.amount;

    final result = await showDialog<_RefundDialogResult>(
      context: context,
      builder: (_) => _RefundDialog(
        originalAmount: defaultRefundAmount,
        description: transaction.description,
      ),
    );

    if (result == null) return;

    try {
      final adjustment = CreditCardAdjustment(
        id: const Uuid().v4(),
        userId: transaction.userId,
        creditCardId: transaction.creditCardId!,
        type: 'refund',
        amount: result.amount,
        remainingAmount: result.amount,
        adjustmentDate: result.receivedAt,
        description: 'Estorno ${transaction.description}',
        relatedTransactionId: transaction.id,
        createdAt: DateTime.now(),
      );

      await ref
          .read(creditCardAdjustmentRepositoryProvider)
          .createAdjustment(adjustment);

      await _markCoveredTransactionsAsPaid(
        ref,
        refundAmount: result.amount,
        paidAt: result.receivedAt,
      );

      ref.invalidate(tx.transactionsProvider(transaction.userId));
      ref.invalidate(
        dash.filteredTransactionsByMonthProvider(transaction.userId),
      );
      ref.invalidate(dash.monthlySummaryProvider(transaction.userId));
      ref.invalidate(dash.dashboardActiveUserSummaryProvider);
      ref.invalidate(dash.creditCardStatementsProvider(transaction.userId));
      ref.invalidate(
        creditCardAdjustmentsByCardProvider(
          CreditCardAdjustmentQuery(
            userId: transaction.userId,
            creditCardId: transaction.creditCardId!,
          ),
        ),
      );
      ref.invalidate(creditCardDebtsProvider(transaction.userId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estorno registrado no cartão')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar estorno: $e')),
        );
      }
    }
  }

  Future<void> _markCoveredTransactionsAsPaid(
    WidgetRef ref, {
    required double refundAmount,
    required DateTime paidAt,
  }) async {
    final creditCardId = transaction.creditCardId;
    final dueDate = transaction.dueDate;

    if (creditCardId == null || dueDate == null) return;

    final transactions =
        await ref.read(tx.transactionsProvider(transaction.userId).future);

    final monthTransactions = transactions.where((t) {
      if (t.userId != transaction.userId) return false;
      if (t.type != 'expense') return false;
      if (t.creditCardId != creditCardId) return false;
      if (t.dueDate == null) return false;
      if (t.status == 'paid') return false;

      return t.dueDate!.year == dueDate.year && t.dueDate!.month == dueDate.month;
    }).toList()
      ..sort((a, b) {
        final aDate = a.dueDate ?? a.createdAt;
        final bDate = b.dueDate ?? b.createdAt;
        final byDate = aDate.compareTo(bDate);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });

    double remaining = refundAmount;

    for (final item in monthTransactions) {
      if (remaining < item.amount) {
        continue;
      }

      await ref.read(tx.transactionControllerProvider).updateStatus(
            transactionId: item.id,
            status: 'paid',
            paidAt: paidAt,
          );

      remaining -= item.amount;

      if (remaining <= 0) {
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleParts = <String>[];

    if (transaction.storeName != null &&
        transaction.storeName!.trim().isNotEmpty) {
      subtitleParts.add(transaction.storeName!.trim());
    }

    if (transaction.installmentNumber != null &&
        transaction.installmentTotal != null) {
      subtitleParts.add(
        '${transaction.installmentNumber}/${transaction.installmentTotal}',
      );
    }

    final subtitle = subtitleParts.join(' • ');
    final statusColor = _statusColor(effectiveStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: Icon(
                    _isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withOpacity(0.22),
                              ),
                            ),
                            child: Text(
                              _statusLabel(effectiveStatus),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
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
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    if (_isFinancing &&
                        transaction.paidAmount != null &&
                        transaction.paidAmount != transaction.amount) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Pago: ${_formatCurrency(transaction.paidAmount!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                    if (_isFinancing && transaction.discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Desconto: ${_formatCurrency(transaction.discountAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (_isExpense && transaction.dueDate != null)
                      Text(
                        _formatDate(transaction.dueDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    if (!_isExpense && transaction.receivedDate != null)
                      Text(
                        _formatDate(transaction.receivedDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withOpacity(0.08),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final canUseRow = constraints.maxWidth >= 640;

                final buttons = <Widget>[
                  if (onEdit != null)
                    Expanded(
                      child: _CompactActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        onPressed: onEdit,
                      ),
                    ),
                  if (_isExpense && !_isPaid) ...[
                    if (onEdit != null) const SizedBox(width: 8),
                    Expanded(
                      child: _CompactActionButton(
                        icon: Icons.check_circle_outline,
                        label: 'Pagar',
                        onPressed: () => _handlePay(context, ref),
                      ),
                    ),
                  ],
                  if (_canRefundCreditCardPurchase) ...[
                    if (onEdit != null || (_isExpense && !_isPaid))
                      const SizedBox(width: 8),
                    Expanded(
                      child: _CompactActionButton(
                        icon: Icons.undo,
                        label: 'Estornar',
                        onPressed: () => _handleRefund(context, ref),
                      ),
                    ),
                  ],
                  if (onDelete != null) ...[
                    if (onEdit != null ||
                        (_isExpense && !_isPaid) ||
                        _canRefundCreditCardPurchase)
                      const SizedBox(width: 8),
                    Expanded(
                      child: _CompactActionButton(
                        icon: Icons.delete_outline,
                        label: 'Excluir',
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ];

                if (canUseRow) {
                  return Row(children: buttons);
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onEdit != null)
                      _CompactActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        onPressed: onEdit,
                      ),
                    if (_isExpense && !_isPaid)
                      _CompactActionButton(
                        icon: Icons.check_circle_outline,
                        label: 'Pagar',
                        onPressed: () => _handlePay(context, ref),
                      ),
                    if (_canRefundCreditCardPurchase)
                      _CompactActionButton(
                        icon: Icons.undo,
                        label: 'Estornar',
                        onPressed: () => _handleRefund(context, ref),
                      ),
                    if (onDelete != null)
                      _CompactActionButton(
                        icon: Icons.delete_outline,
                        label: 'Excluir',
                        onPressed: onDelete,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(
          color: Colors.white.withOpacity(0.16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SimplePayDialog extends StatefulWidget {
  const _SimplePayDialog();

  @override
  State<_SimplePayDialog> createState() => _SimplePayDialogState();
}

class _SimplePayDialogState extends State<_SimplePayDialog> {
  DateTime _paidAt = DateTime.now();

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _paidAt,
    );

    if (selected != null) {
      setState(() => _paidAt = selected);
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar como paga'),
      content: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Data do pagamento: ${_formatDate(_paidAt)}'),
        trailing: OutlinedButton(
          onPressed: _pickDate,
          child: const Text('Escolher data'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _SimplePayDialogResult(paidAt: _paidAt),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _SimplePayDialogResult {
  final DateTime paidAt;

  const _SimplePayDialogResult({
    required this.paidAt,
  });
}

class _FinancingPayDialog extends StatefulWidget {
  final double originalAmount;

  const _FinancingPayDialog({
    required this.originalAmount,
  });

  @override
  State<_FinancingPayDialog> createState() => _FinancingPayDialogState();
}

class _FinancingPayDialogState extends State<_FinancingPayDialog> {
  late final TextEditingController _paidAmountController;
  DateTime _paidAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _paidAmountController = TextEditingController(
      text: widget.originalAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _paidAt,
    );

    if (selected != null) {
      setState(() => _paidAt = selected);
    }
  }

  double get _previewDiscount {
    final paidAmount =
        double.tryParse(_paidAmountController.text.replaceAll(',', '.'));
    if (paidAmount == null) return 0.0;
    final discount = widget.originalAmount - paidAmount;
    return discount < 0 ? 0.0 : discount;
  }

  void _confirm() {
    final paidAmount =
        double.tryParse(_paidAmountController.text.replaceAll(',', '.'));

    if (paidAmount == null || paidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o valor pago')),
      );
      return;
    }

    if (paidAmount > widget.originalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O valor pago não pode ser maior que o valor original',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _FinancingPayDialogResult(
        paidAmount: paidAmount,
        paidAt: _paidAt,
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quitar financiamento'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valor original: ${_formatCurrency(widget.originalAmount)}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor realmente pago',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Desconto calculado: ${_formatCurrency(_previewDiscount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Data do pagamento: ${_formatDate(_paidAt)}'),
                trailing: OutlinedButton(
                  onPressed: _pickDate,
                  child: const Text('Escolher data'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _FinancingPayDialogResult {
  final double paidAmount;
  final DateTime paidAt;

  const _FinancingPayDialogResult({
    required this.paidAmount,
    required this.paidAt,
  });
}

class _RefundDialog extends StatefulWidget {
  final double originalAmount;
  final String description;

  const _RefundDialog({
    required this.originalAmount,
    required this.description,
  });

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  late final TextEditingController _amountController;
  DateTime _receivedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.originalAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _receivedAt,
    );

    if (selected != null) {
      setState(() => _receivedAt = selected);
    }
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor de estorno válido')),
      );
      return;
    }

    Navigator.of(context).pop(
      _RefundDialogResult(
        amount: amount,
        receivedAt: _receivedAt,
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar estorno'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Compra: ${widget.description}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Valor total da compra: ${_formatCurrency(widget.originalAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor do estorno',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Data do estorno: ${_formatDate(_receivedAt)}'),
                trailing: OutlinedButton(
                  onPressed: _pickDate,
                  child: const Text('Escolher data'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Esse estorno será salvo como crédito interno do cartão.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _RefundDialogResult {
  final double amount;
  final DateTime receivedAt;

  const _RefundDialogResult({
    required this.amount,
    required this.receivedAt,
  });
}