import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/financing_contract.dart';
import '../../domain/entities/financing_installment.dart';
import '../controllers/financing_providers.dart';

class FinancingDetailsPage extends ConsumerWidget {
  final FinancingContract contract;

  const FinancingDetailsPage({
    super.key,
    required this.contract,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installmentsAsync =
        ref.watch(financingInstallmentsProvider(contract.id));
    final summaryAsync = ref.watch(financingSummaryProvider(contract.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(contract.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            summaryAsync.when(
              data: (summary) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      children: [
                        _SummaryItem(
                          title: 'Valor total',
                          value: _formatCurrency(summary.totalAmount),
                        ),
                        _SummaryItem(
                          title: 'Pago até agora',
                          value: _formatCurrency(summary.paidAmount),
                        ),
                        _SummaryItem(
                          title: 'Desconto acumulado',
                          value: _formatCurrency(summary.totalDiscount),
                        ),
                        _SummaryItem(
                          title: 'Parcelas pagas',
                          value: '${summary.paidInstallments}',
                        ),
                        _SummaryItem(
                          title: 'Parcelas restantes',
                          value: '${summary.remainingInstallments}',
                        ),
                        _SummaryItem(
                          title: 'Valor restante',
                          value: _formatCurrency(summary.remainingAmount),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Erro ao carregar resumo: $error'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Parcelas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            installmentsAsync.when(
              data: (installments) {
                if (installments.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhuma parcela encontrada'),
                    ),
                  );
                }

                return Column(
                  children: installments.map((installment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InstallmentCard(
                        contractId: contract.id,
                        installment: installment,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text(
                'Erro ao carregar parcelas: $error',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentCard extends ConsumerWidget {
  final String contractId;
  final FinancingInstallment installment;

  const _InstallmentCard({
    required this.contractId,
    required this.installment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.08),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parcela ${installment.installmentNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valor original: ${_formatCurrency(installment.originalAmount)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vencimento: ${_formatDate(installment.dueDate)}',
                  ),
                  if (installment.isPaid) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Valor pago: ${_formatCurrency(installment.paidAmount ?? 0)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Desconto: ${_formatCurrency(installment.discountAmount)}',
                    ),
                    if (installment.paidAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pago em: ${_formatDate(installment.paidAt!)}',
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(isPaid: installment.isPaid),
                const SizedBox(height: 10),
                if (!installment.isPaid)
                  FilledButton(
                    onPressed: () async {
                      final result =
                          await showDialog<_PayInstallmentDialogResult>(
                        context: context,
                        builder: (_) => _PayInstallmentDialog(
                          originalAmount: installment.originalAmount,
                        ),
                      );

                      if (result == null) return;

                      try {
                        await ref.read(financingActionsProvider).payInstallment(
                              installment: installment,
                              paidAmount: result.paidAmount,
                              paidAt: result.paidAt,
                            );

                        ref.invalidate(financingInstallmentsProvider(contractId));
                        ref.invalidate(financingSummaryProvider(contractId));

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Parcela quitada com sucesso'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao quitar parcela: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Quitar'),
                  ),
              ],
            ),
          ],
        ),
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
}

class _StatusBadge extends StatelessWidget {
  final bool isPaid;

  const _StatusBadge({
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        isPaid ? 'Paga' : 'Pendente',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PayInstallmentDialog extends StatefulWidget {
  final double originalAmount;

  const _PayInstallmentDialog({
    required this.originalAmount,
  });

  @override
  State<_PayInstallmentDialog> createState() => _PayInstallmentDialogState();
}

class _PayInstallmentDialogState extends State<_PayInstallmentDialog> {
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
            'O valor pago não pode ser maior que o valor da parcela',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _PayInstallmentDialogResult(
        paidAmount: paidAmount,
        paidAt: _paidAt,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final previewDiscount = (() {
      final paidAmount =
          double.tryParse(_paidAmountController.text.replaceAll(',', '.'));
      if (paidAmount == null) return 0.0;
      final discount = widget.originalAmount - paidAmount;
      return discount < 0 ? 0.0 : discount;
    })();

    return AlertDialog(
      title: const Text('Quitar parcela'),
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
                  'Desconto calculado: ${_formatCurrency(previewDiscount)}',
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

class _PayInstallmentDialogResult {
  final double paidAmount;
  final DateTime paidAt;

  const _PayInstallmentDialogResult({
    required this.paidAmount,
    required this.paidAt,
  });
}