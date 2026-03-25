import 'package:flutter/material.dart';

import '../../../category/domain/entities/app_category.dart';

class TransactionFormCard extends StatelessWidget {
  final String selectedType;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final TextEditingController installmentCountController;
  final List<AppCategory> expenseCategories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
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
    required this.descriptionController,
    required this.amountController,
    required this.installmentCountController,
    required this.expenseCategories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
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
  Widget build(BuildContext context) {
    final isExpense = selectedType == 'expense';
    final title = isExpense ? 'Nova despesa' : 'Nova receita';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Despesa'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text('Receita'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: onTypeChanged,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isInstallment && isExpense
                      ? 'Valor total da compra'
                      : 'Valor',
                ),
              ),
              const SizedBox(height: 16),
              if (isExpense) ...[
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                  ),
                  items: expenseCategories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: onCategoryChanged,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isInstallment,
                  onChanged: onInstallmentChanged,
                  title: const Text('Compra parcelada'),
                  subtitle: const Text(
                    'Serão geradas despesas mensais automaticamente',
                  ),
                ),
                if (isInstallment) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: installmentCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de parcelas',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Apenas o valor da parcela entrará em cada mês.',
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isExpense
                      ? (isInstallment
                          ? 'Data da primeira parcela: ${_formatDate(mainDate)}'
                          : 'Data de vencimento: ${_formatDate(mainDate)}')
                      : 'Data de recebimento: ${_formatDate(mainDate)}',
                ),
                trailing: OutlinedButton(
                  onPressed: onPickMainDate,
                  child: const Text('Escolher data'),
                ),
              ),
              if (isExpense && !isInstallment) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
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
                    DropdownMenuItem(
                      value: 'overdue',
                      child: Text('Atrasado'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markAsPaid,
                  onChanged: onMarkAsPaidChanged,
                  title: const Text('Marcar como pago'),
                  subtitle: const Text(
                    'Você pode ajustar a data real manualmente',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    paidAtDate != null
                        ? 'Data de pagamento: ${_formatDate(paidAtDate!)}'
                        : 'Data de pagamento: não informada',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: selectedStatus == 'paid'
                            ? onPickPaidAtDate
                            : null,
                        child: const Text('Escolher data'),
                      ),
                      if (paidAtDate != null)
                        TextButton(
                          onPressed: onClearPaidAt,
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isInstallment ? 'Gerar parcelas' : 'Salvar transação',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}