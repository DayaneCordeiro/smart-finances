import 'dart:math';

import 'package:flutter/material.dart';

class TransactionFormCard extends StatefulWidget {
  final String selectedType;

  final TextEditingController storeController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final TextEditingController installmentCountController;

  final List<dynamic> expenseCategories;
  final List<dynamic> creditCards;

  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  final String? selectedCreditCardId;
  final ValueChanged<String?> onCreditCardChanged;

  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  final bool markAsPaid;
  final ValueChanged<bool> onMarkAsPaidChanged;

  final bool isInstallment;
  final ValueChanged<bool> onInstallmentChanged;

  final DateTime mainDate;
  final VoidCallback onPickMainDate;

  final DateTime? paidAtDate;
  final VoidCallback onPickPaidAtDate;
  final VoidCallback onClearPaidAt;

  final bool isSaving;
  final VoidCallback onSave;

  final ValueChanged<Set<String>> onTypeChanged;

  const TransactionFormCard({
    super.key,
    required this.selectedType,
    required this.storeController,
    required this.descriptionController,
    required this.amountController,
    required this.installmentCountController,
    required this.expenseCategories,
    required this.creditCards,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.selectedCreditCardId,
    required this.onCreditCardChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.markAsPaid,
    required this.onMarkAsPaidChanged,
    required this.isInstallment,
    required this.onInstallmentChanged,
    required this.mainDate,
    required this.onPickMainDate,
    required this.paidAtDate,
    required this.onPickPaidAtDate,
    required this.onClearPaidAt,
    required this.isSaving,
    required this.onSave,
    required this.onTypeChanged,
  });

  @override
  State<TransactionFormCard> createState() => _TransactionFormCardState();
}

class _TransactionFormCardState extends State<TransactionFormCard> {
  @override
  void initState() {
    super.initState();
    widget.amountController.addListener(_refreshPreview);
    widget.installmentCountController.addListener(_refreshPreview);
  }

  @override
  void didUpdateWidget(covariant TransactionFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.amountController != widget.amountController) {
      oldWidget.amountController.removeListener(_refreshPreview);
      widget.amountController.addListener(_refreshPreview);
    }

    if (oldWidget.installmentCountController !=
        widget.installmentCountController) {
      oldWidget.installmentCountController.removeListener(_refreshPreview);
      widget.installmentCountController.addListener(_refreshPreview);
    }
  }

  @override
  void dispose() {
    widget.amountController.removeListener(_refreshPreview);
    widget.installmentCountController.removeListener(_refreshPreview);
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  double? get _parsedAmount {
    return double.tryParse(
      widget.amountController.text.trim().replaceAll(',', '.'),
    );
  }

  int? get _parsedInstallments {
    return int.tryParse(widget.installmentCountController.text.trim());
  }

  double _ceilToCents(double value) {
    return (value * 100).ceil() / 100;
  }

  double? get _installmentAmountPreview {
    final amount = _parsedAmount;
    final installments = _parsedInstallments;

    if (amount == null || amount <= 0) return null;
    if (installments == null || installments < 2) return null;

    return _ceilToCents(amount / installments);
  }

  DateTime get _lastInstallmentDate {
    final installments = _parsedInstallments;
    if (installments == null || installments < 2) {
      return widget.mainDate;
    }

    return DateTime(
      widget.mainDate.year,
      widget.mainDate.month + (installments - 1),
      widget.mainDate.day,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.selectedType == 'expense';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'expense',
                icon: Icon(Icons.arrow_upward),
                label: Text('Despesa'),
              ),
              ButtonSegment<String>(
                value: 'income',
                icon: Icon(Icons.arrow_downward),
                label: Text('Receita'),
              ),
            ],
            selected: {widget.selectedType},
            onSelectionChanged: widget.onTypeChanged,
          ),
          const SizedBox(height: 20),

          if (isExpense && widget.isInstallment) ...[
            TextField(
              controller: widget.storeController,
              decoration: const InputDecoration(
                labelText: 'Loja',
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: widget.descriptionController,
            decoration: InputDecoration(
              labelText: isExpense ? 'Descrição' : 'Descrição da receita',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: widget.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isExpense ? 'Valor' : 'Valor recebido',
            ),
          ),
          const SizedBox(height: 16),

          if (isExpense) ...[
            DropdownButtonFormField<String>(
              value: widget.selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoria',
              ),
              items: widget.expenseCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id as String,
                  child: Text(category.name as String),
                );
              }).toList(),
              onChanged: widget.onCategoryChanged,
            ),
            const SizedBox(height: 16),
          ],

          if (isExpense) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compra parcelada'),
              subtitle: const Text(
                'Se ativo, gera despesas mensais automaticamente',
              ),
              value: widget.isInstallment,
              onChanged: widget.onInstallmentChanged,
            ),
            const SizedBox(height: 8),
          ],

          if (isExpense && widget.isInstallment) ...[
            DropdownButtonFormField<String>(
              value: widget.selectedCreditCardId,
              decoration: const InputDecoration(
                labelText: 'Cartão de crédito',
              ),
              items: widget.creditCards.map((card) {
                return DropdownMenuItem<String>(
                  value: card.id as String,
                  child: Text(card.name as String),
                );
              }).toList(),
              onChanged: widget.onCreditCardChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.installmentCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade de parcelas',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prévia do parcelamento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Primeira parcela',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(widget.mainDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Última parcela',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_lastInstallmentDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Valor da parcela',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _installmentAmountPreview != null
                        ? _formatCurrency(_installmentAmountPreview!)
                        : '--',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isExpense
                  ? widget.isInstallment
                      ? 'Data da primeira parcela'
                      : 'Data de vencimento'
                  : 'Data de recebimento',
            ),
            subtitle: Text(_formatDate(widget.mainDate)),
            trailing: OutlinedButton(
              onPressed: widget.onPickMainDate,
              child: const Text('Escolher data'),
            ),
          ),
          const SizedBox(height: 16),

          if (isExpense && !widget.isInstallment) ...[
            DropdownButtonFormField<String>(
              value: widget.selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('Pendente'),
                ),
                DropdownMenuItem(
                  value: 'paid',
                  child: Text('Pago'),
                ),
              ],
              onChanged: widget.onStatusChanged,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Marcar como pago'),
              value: widget.markAsPaid,
              onChanged: widget.onMarkAsPaidChanged,
            ),
            const SizedBox(height: 8),
            if (widget.markAsPaid) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do pagamento'),
                subtitle: Text(
                  widget.paidAtDate != null
                      ? _formatDate(widget.paidAtDate!)
                      : 'Não informada',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onPickPaidAtDate,
                      child: const Text('Escolher data'),
                    ),
                    if (widget.paidAtDate != null)
                      OutlinedButton(
                        onPressed: widget.onClearPaidAt,
                        child: const Text('Limpar'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],

          if (!isExpense) ...[
            const SizedBox(height: 8),
            Text(
              'Receitas são registradas como recebidas na data informada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.isSaving ? null : widget.onSave,
              child: Text(
                widget.isSaving ? 'Salvando...' : 'Salvar transação',
              ),
            ),
          ),
        ],
      ),
    );
  }
}