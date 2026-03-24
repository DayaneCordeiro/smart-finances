import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/controllers/category_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/transaction_providers.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategoryId;
  String _selectedStatus = 'pending';
  bool _markAsPaid = false;
  bool _isSaving = false;

  DateTime _mainDate = DateTime.now();
  DateTime? _paidAtDate;

  String _effectiveStatusForDisplay(transaction) {
    if (transaction.status == 'paid' || transaction.status == 'received') {
      return transaction.status;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (transaction.type == 'expense' && transaction.dueDate != null) {
      final dueDate = DateTime(
        transaction.dueDate.year,
        transaction.dueDate.month,
        transaction.dueDate.day,
      );

      if (transaction.status == 'pending' && dueDate.isBefore(today)) {
        return 'overdue';
      }
    }

    if (transaction.type == 'income' && transaction.receivedDate != null) {
      final receivedDate = DateTime(
        transaction.receivedDate.year,
        transaction.receivedDate.month,
        transaction.receivedDate.day,
      );

      if (transaction.status == 'pending' && receivedDate.isBefore(today)) {
        return 'overdue';
      }
    }

    return transaction.status;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickMainDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _mainDate,
    );

    if (selected != null) {
      setState(() => _mainDate = selected);
    }
  }

  Future<void> _pickPaidAtDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _paidAtDate ?? DateTime.now(),
    );

    if (selected != null) {
      setState(() => _paidAtDate = selected);
    }
  }

  void _syncStatusWithSwitch(bool value) {
    setState(() {
      _markAsPaid = value;

      if (value) {
        _selectedStatus = _selectedType == 'income' ? 'received' : 'paid';
        _paidAtDate ??= DateTime.now();
      } else {
        _selectedStatus = 'pending';
        _paidAtDate = null;
      }
    });
  }

  Future<void> _saveTransaction(String userId) async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(transactionControllerProvider).createTransaction(
            userId: userId,
            categoryId: _selectedCategoryId!,
            type: _selectedType,
            description: _descriptionController.text,
            amount: amount,
            dueDate: _selectedType == 'expense' ? _mainDate : null,
            receivedDate: _selectedType == 'income' ? _mainDate : null,
            status: _selectedStatus,
            paidAt: _paidAtDate,
          );

      _descriptionController.clear();
      _amountController.clear();

      setState(() {
        _selectedCategoryId = null;
        _selectedStatus = 'pending';
        _markAsPaid = false;
        _mainDate = DateTime.now();
        _paidAtDate = null;
      });

      ref.invalidate(transactionsProvider(userId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação salva com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar transação: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changeStatusDialog({
    required String transactionId,
    required String currentStatus,
    required DateTime? currentPaidAt,
    required String type,
    required String userId,
  }) async {
    String tempStatus = currentStatus;
    DateTime? tempPaidAt = currentPaidAt;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Alterar status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pendente'),
                      ),
                      if (type == 'expense')
                        const DropdownMenuItem(
                          value: 'paid',
                          child: Text('Pago'),
                        ),
                      if (type == 'income')
                        const DropdownMenuItem(
                          value: 'received',
                          child: Text('Recebido'),
                        ),
                      const DropdownMenuItem(
                        value: 'overdue',
                        child: Text('Atrasado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setModalState(() {
                        tempStatus = value;

                        if (value == 'paid' || value == 'received') {
                          tempPaidAt ??= DateTime.now();
                        }

                        if (value == 'pending' || value == 'overdue') {
                          tempPaidAt = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tempPaidAt != null
                          ? 'Data de pagamento/recebimento: ${_formatDate(tempPaidAt!)}'
                          : 'Data de pagamento/recebimento: não informada',
                    ),
                    trailing: OutlinedButton(
                      onPressed: (tempStatus == 'paid' || tempStatus == 'received')
                          ? () async {
                              final selected = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: tempPaidAt ?? DateTime.now(),
                              );

                              if (selected != null) {
                                setModalState(() => tempPaidAt = selected);
                              }
                            }
                          : null,
                      child: const Text('Escolher data'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref.read(transactionControllerProvider).updateStatus(
                          transactionId: transactionId,
                          status: tempStatus,
                          paidAt: tempPaidAt,
                        );

                    ref.invalidate(transactionsProvider(userId));

                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUserAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        backgroundColor: Colors.transparent,
      ),
      body: activeUserAsync.when(
        data: (activeUser) {
          if (activeUser == null) {
            return const Center(child: Text('Nenhum usuário ativo'));
          }

          final categoriesAsync = ref.watch(categoriesProvider(activeUser.id));
          final transactionsAsync = ref.watch(transactionsProvider(activeUser.id));

          return categoriesAsync.when(
            data: (categories) {
              final filteredCategories = categories
                  .where((category) => category.type == _selectedType)
                  .toList();

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
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
                              selected: {_selectedType},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _selectedType = value.first;
                                  _selectedCategoryId = null;
                                  _selectedStatus = 'pending';
                                  _markAsPaid = false;
                                  _paidAtDate = null;
                                  _mainDate = DateTime.now();
                                });
                              },
                            ),
                            const SizedBox(height: 16),
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
                            DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                              ),
                              items: filteredCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategoryId = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _selectedType == 'expense'
                                    ? 'Data de vencimento: ${_formatDate(_mainDate)}'
                                    : 'Data de recebimento: ${_formatDate(_mainDate)}',
                              ),
                              trailing: OutlinedButton(
                                onPressed: _pickMainDate,
                                child: const Text('Escolher data'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pendente'),
                                ),
                                if (_selectedType == 'expense')
                                  const DropdownMenuItem(
                                    value: 'paid',
                                    child: Text('Pago'),
                                  ),
                                if (_selectedType == 'income')
                                  const DropdownMenuItem(
                                    value: 'received',
                                    child: Text('Recebido'),
                                  ),
                                const DropdownMenuItem(
                                  value: 'overdue',
                                  child: Text('Atrasado'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _selectedStatus = value;
                                  _markAsPaid =
                                      value == 'paid' || value == 'received';

                                  if (_markAsPaid) {
                                    _paidAtDate ??= DateTime.now();
                                  } else {
                                    _paidAtDate = null;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _markAsPaid,
                              onChanged: _syncStatusWithSwitch,
                              title: Text(
                                _selectedType == 'expense'
                                    ? 'Marcar como pago'
                                    : 'Marcar como recebido',
                              ),
                              subtitle: const Text(
                                'Você pode ajustar a data real manualmente',
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _paidAtDate != null
                                    ? 'Data de pagamento/recebimento: ${_formatDate(_paidAtDate!)}'
                                    : 'Data de pagamento/recebimento: não informada',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: (_selectedStatus == 'paid' ||
                                            _selectedStatus == 'received')
                                        ? _pickPaidAtDate
                                        : null,
                                    child: const Text('Escolher data'),
                                  ),
                                  if (_paidAtDate != null)
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _paidAtDate = null);
                                      },
                                      child: const Text('Limpar'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => _saveTransaction(activeUser.id),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Salvar transação'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: transactionsAsync.when(
                        data: (transactions) {
                          if (transactions.isEmpty) {
                            return const Center(
                              child: Text('Nenhuma transação cadastrada'),
                            );
                          }

                          return ListView.separated(
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              final effectiveStatus = _effectiveStatusForDisplay(transaction);

                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      transaction.type == 'income'
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                    ),
                                  ),
                                  title: Text(transaction.description),
                                  subtitle: Text(
                                    [
                                      transaction.type == 'income'
                                          ? 'Receita'
                                          : 'Despesa',
                                      _formatCurrency(transaction.amount),
                                      transaction.type == 'expense'
                                          ? 'Vencimento: ${_formatDate(transaction.dueDate!)}'
                                          : 'Recebimento: ${_formatDate(transaction.receivedDate!)}',
                                      'Status: ${_statusLabel(effectiveStatus)}',
                                      if (transaction.paidAt != null)
                                        'Pago/Recebido em: ${_formatDate(transaction.paidAt!)}',
                                    ].join(' • '),
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _statusIcon(effectiveStatus),
                                          color: _statusColor(effectiveStatus),
                                        ),
                                        onPressed: () => _changeStatusDialog(
                                          transactionId: transaction.id,
                                          currentStatus: transaction.status,
                                          currentPaidAt: transaction.paidAt,
                                          type: transaction.type,
                                          userId: activeUser.id,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          await ref
                                              .read(transactionControllerProvider)
                                              .deleteTransaction(transaction.id);

                                          ref.invalidate(
                                            transactionsProvider(activeUser.id),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Erro ao carregar transações: $error'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Erro ao carregar categorias: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro ao carregar usuário ativo: $error'),
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

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'paid':
        return 'Pago';
      case 'received':
        return 'Recebido';
      case 'overdue':
        return 'Atrasado';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid':
      case 'received':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning_amber_rounded;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'received':
        return Colors.green;
      case 'overdue':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.white54;
    }
  }
}