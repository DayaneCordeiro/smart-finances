import 'package:flutter/material.dart';

import '../../../category/domain/entities/app_category.dart';
import '../../domain/entities/finance_transaction.dart';

class EditTransactionPage extends StatefulWidget {
  final FinanceTransaction transaction;
  final List<AppCategory> categories;

  const EditTransactionPage({
    super.key,
    required this.transaction,
    required this.categories,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  String? _categoryId;
  late String _status;
  late DateTime _mainDate;
  DateTime? _paidAt;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );

    _categoryId =
        widget.transaction.type == 'expense' ? widget.transaction.categoryId : null;
    _status = widget.transaction.type == 'income'
        ? 'received'
        : widget.transaction.status;
    _mainDate = widget.transaction.type == 'expense'
        ? widget.transaction.dueDate!
        : widget.transaction.receivedDate!;
    _paidAt = widget.transaction.type == 'income'
        ? widget.transaction.receivedDate
        : widget.transaction.paidAt;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickMainDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _mainDate,
    );

    if (picked != null) {
      setState(() => _mainDate = picked);
    }
  }

  Future<void> _pickPaidAt() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _paidAt ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => _paidAt = picked);
    }
  }

  void _save() {
    final parsedValue = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );

    if (parsedValue == null || parsedValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido')),
      );
      return;
    }

    if (widget.transaction.type == 'expense' && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descrição é obrigatória')),
      );
      return;
    }

    Navigator.of(context).pop(
      EditTransactionResult(
        description: _descriptionController.text.trim(),
        amount: parsedValue,
        categoryId: _categoryId,
        mainDate: _mainDate,
        status: widget.transaction.type == 'income' ? 'received' : _status,
        paidAt: widget.transaction.type == 'income' ? _mainDate : _paidAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories =
        widget.categories.where((c) => c.type == 'expense').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar transação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                  ),
                ),
                const SizedBox(height: 16),
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
                if (widget.transaction.type == 'expense') ...[
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                    ),
                    items: expenseCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _categoryId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    widget.transaction.type == 'expense'
                        ? 'Data de vencimento: ${_formatDate(_mainDate)}'
                        : 'Data de recebimento: ${_formatDate(_mainDate)}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: _pickMainDate,
                    child: const Text('Escolher data'),
                  ),
                ),
                if (widget.transaction.type == 'expense' &&
                    !widget.transaction.isInstallment) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
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
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _status = value;
                        if (value == 'pending' || value == 'overdue') {
                          _paidAt = null;
                        } else {
                          _paidAt ??= DateTime.now();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _paidAt != null
                          ? 'Data de pagamento: ${_formatDate(_paidAt!)}'
                          : 'Data de pagamento: não informada',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _status == 'paid' ? _pickPaidAt : null,
                          child: const Text('Escolher data'),
                        ),
                        if (_paidAt != null)
                          TextButton(
                            onPressed: () {
                              setState(() => _paidAt = null);
                            },
                            child: const Text('Limpar'),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar'),
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

class EditTransactionResult {
  final String description;
  final double amount;
  final String? categoryId;
  final DateTime mainDate;
  final String status;
  final DateTime? paidAt;

  const EditTransactionResult({
    required this.description,
    required this.amount,
    required this.categoryId,
    required this.mainDate,
    required this.status,
    required this.paidAt,
  });
}