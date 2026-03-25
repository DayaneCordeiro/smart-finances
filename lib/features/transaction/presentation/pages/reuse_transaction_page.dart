import 'package:flutter/material.dart';

import '../../domain/entities/finance_transaction.dart';

class ReuseTransactionPage extends StatefulWidget {
  final FinanceTransaction transaction;
  final DateTime suggestedDate;

  const ReuseTransactionPage({
    super.key,
    required this.transaction,
    required this.suggestedDate,
  });

  @override
  State<ReuseTransactionPage> createState() => _ReuseTransactionPageState();
}

class _ReuseTransactionPageState extends State<ReuseTransactionPage> {
  late final TextEditingController _amountController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _selectedDate = widget.suggestedDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido')),
      );
      return;
    }

    Navigator.of(context).pop(
      ReuseTransactionPageResult(
        amount: amount,
        nextDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.type == 'expense';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copiar para o próximo mês'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isExpense
                        ? 'Novo vencimento: ${_formatDate(_selectedDate)}'
                        : 'Nova data: ${_formatDate(_selectedDate)}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: _pickDate,
                    child: const Text('Escolher data'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Criar cópia'),
                  ),
                ),
              ],
            ),
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

class ReuseTransactionPageResult {
  final double amount;
  final DateTime nextDate;

  const ReuseTransactionPageResult({
    required this.amount,
    required this.nextDate,
  });
}