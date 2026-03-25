import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/domain/entities/app_category.dart';
import '../../../category/presentation/controllers/category_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../domain/entities/finance_transaction.dart';
import '../controllers/transaction_providers.dart';
import 'edit_transaction_page.dart';
import 'reuse_transaction_page.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentCountController = TextEditingController(text: '2');

  String _selectedType = 'expense';
  String? _selectedCategoryId;
  String _selectedStatus = 'pending';
  bool _markAsPaid = false;
  bool _isSaving = false;
  bool _isInstallment = false;

  DateTime _mainDate = DateTime.now();
  DateTime? _paidAtDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _installmentCountController.dispose();
    super.dispose();
  }

  void _refreshFinancialData(String userId) {
    ref.invalidate(transactionsProvider(userId));
    ref.invalidate(filteredTransactionsByMonthProvider(userId));
    ref.invalidate(monthlySummaryProvider(userId));
    ref.invalidate(dashboardActiveUserSummaryProvider);
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
        _selectedStatus = 'paid';
        _paidAtDate ??= DateTime.now();
      } else {
        _selectedStatus = 'pending';
        _paidAtDate = null;
      }
    });
  }

  Future<void> _saveTransaction(String userId) async {
    if (_selectedType == 'expense' && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    final parsedValue = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );

    if (parsedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final wasInstallment = _isInstallment;

      if (_selectedType == 'income') {
        await ref.read(transactionControllerProvider).createTransaction(
              userId: userId,
              categoryId: 'income_fixed',
              type: 'income',
              description: _descriptionController.text,
              amount: parsedValue,
              dueDate: null,
              receivedDate: _mainDate,
              status: 'received',
              paidAt: _mainDate,
            );
      } else if (_isInstallment) {
        final installmentCount =
            int.tryParse(_installmentCountController.text.trim());

        if (installmentCount == null || installmentCount < 2) {
          throw Exception('Informe uma quantidade válida de parcelas');
        }

        await ref.read(transactionControllerProvider).createExpenseInstallments(
              userId: userId,
              categoryId: _selectedCategoryId!,
              description: _descriptionController.text,
              totalAmount: parsedValue,
              installmentCount: installmentCount,
              firstDueDate: _mainDate,
            );
      } else {
        await ref.read(transactionControllerProvider).createTransaction(
              userId: userId,
              categoryId: _selectedCategoryId!,
              type: 'expense',
              description: _descriptionController.text,
              amount: parsedValue,
              dueDate: _mainDate,
              receivedDate: null,
              status: _selectedStatus,
              paidAt: _paidAtDate,
            );
      }

      _descriptionController.clear();
      _amountController.clear();

      setState(() {
        _selectedCategoryId = null;
        _selectedStatus = 'pending';
        _markAsPaid = false;
        _mainDate = DateTime.now();
        _paidAtDate = null;
        _isInstallment = false;
        _installmentCountController.text = '2';
      });

      _refreshFinancialData(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasInstallment
                ? 'Parcelas geradas com sucesso'
                : 'Transação salva com sucesso',
          ),
        ),
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

  Future<_StatusDialogResult?> _showChangeStatusDialog({
    required String currentStatus,
    required DateTime? currentPaidAt,
    required String type,
  }) async {
    String tempStatus = currentStatus;
    DateTime? tempPaidAt = currentPaidAt;

    return showDialog<_StatusDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Alterar status'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
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
                          onPressed:
                              (tempStatus == 'paid' || tempStatus == 'received')
                                  ? () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                        initialDate: tempPaidAt ?? DateTime.now(),
                                      );

                                      if (selected != null) {
                                        setModalState(
                                          () => tempPaidAt = selected,
                                        );
                                      }
                                    }
                                  : null,
                          child: const Text('Escolher data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      _StatusDialogResult(
                        status: tempStatus,
                        paidAt: tempPaidAt,
                      ),
                    );
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

  String _effectiveStatusForDisplay(FinanceTransaction transaction) {
    if (transaction.status == 'paid' || transaction.status == 'received') {
      return transaction.status;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (transaction.type == 'expense' && transaction.dueDate != null) {
      final dueDate = DateTime(
        transaction.dueDate!.year,
        transaction.dueDate!.month,
        transaction.dueDate!.day,
      );

      if (transaction.status == 'pending' && dueDate.isBefore(today)) {
        return 'overdue';
      }
    }

    if (transaction.type == 'income' && transaction.receivedDate != null) {
      final receivedDate = DateTime(
        transaction.receivedDate!.year,
        transaction.receivedDate!.month,
        transaction.receivedDate!.day,
      );

      if (transaction.status == 'pending' && receivedDate.isBefore(today)) {
        return 'overdue';
      }
    }

    return transaction.status;
  }

  @override
  Widget build(BuildContext context) {
    final activeUserAsync = ref.watch(activeUserProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          final transactionsAsync =
              ref.watch(filteredTransactionsByMonthProvider(activeUser.id));

          return categoriesAsync.when(
            data: (categories) {
              final expenseCategories =
                  categories.where((category) => category.type == 'expense').toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _TransactionMonthSelector(
                                    selectedMonth: selectedMonth,
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
                                    selected: {_selectedType},
                                    onSelectionChanged: (value) {
                                      setState(() {
                                        _selectedType = value.first;
                                        _selectedCategoryId = null;
                                        _selectedStatus = 'pending';
                                        _markAsPaid = false;
                                        _paidAtDate = null;
                                        _isInstallment = false;
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: _isInstallment &&
                                              _selectedType == 'expense'
                                          ? 'Valor total da compra'
                                          : 'Valor',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_selectedType == 'expense') ...[
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
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
                                        setState(() => _selectedCategoryId = value);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _isInstallment,
                                      onChanged: (value) {
                                        setState(() {
                                          _isInstallment = value;
                                          if (value) {
                                            _selectedStatus = 'pending';
                                            _markAsPaid = false;
                                            _paidAtDate = null;
                                          }
                                        });
                                      },
                                      title: const Text('Compra parcelada'),
                                      subtitle: const Text(
                                        'Serão geradas despesas mensais automaticamente',
                                      ),
                                    ),
                                    if (_isInstallment) ...[
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _installmentCountController,
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
                                      _selectedType == 'expense'
                                          ? (_isInstallment
                                              ? 'Data da primeira parcela: ${_formatDate(_mainDate)}'
                                              : 'Data de vencimento: ${_formatDate(_mainDate)}')
                                          : 'Data de recebimento: ${_formatDate(_mainDate)}',
                                    ),
                                    trailing: OutlinedButton(
                                      onPressed: _pickMainDate,
                                      child: const Text('Escolher data'),
                                    ),
                                  ),
                                  if (_selectedType == 'expense' &&
                                      !_isInstallment) ...[
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedStatus,
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
                                          _selectedStatus = value;
                                          _markAsPaid = value == 'paid';

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
                                      title: const Text('Marcar como pago'),
                                      subtitle: const Text(
                                        'Você pode ajustar a data real manualmente',
                                      ),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        _paidAtDate != null
                                            ? 'Data de pagamento: ${_formatDate(_paidAtDate!)}'
                                            : 'Data de pagamento: não informada',
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          OutlinedButton(
                                            onPressed: _selectedStatus == 'paid'
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
                                  ],
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
                                          : Text(
                                              _isInstallment
                                                  ? 'Gerar parcelas'
                                                  : 'Salvar transação',
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 420,
                            child: transactionsAsync.when(
                              data: (transactions) {
                                if (transactions.isEmpty) {
                                  return const Center(
                                    child: Text('Nenhuma transação neste mês'),
                                  );
                                }

                                return ListView.separated(
                                  itemCount: transactions.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final transaction = transactions[index];
                                    final effectiveStatus =
                                        _effectiveStatusForDisplay(transaction);

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
                                            if (transaction.isInstallment &&
                                                transaction.installmentNumber != null &&
                                                transaction.installmentTotal != null)
                                              'Parcela ${transaction.installmentNumber}/${transaction.installmentTotal}',
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
                                              tooltip: 'Editar',
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () async {
                                                final result = await Navigator.of(context)
                                                    .push<EditTransactionResult>(
                                                  MaterialPageRoute(
                                                    builder: (_) => EditTransactionPage(
                                                      transaction: transaction,
                                                      categories: categories,
                                                    ),
                                                  ),
                                                );

                                                if (result == null) return;

                                                try {
                                                  await ref
                                                      .read(transactionControllerProvider)
                                                      .updateTransaction(
                                                        id: transaction.id,
                                                        userId: transaction.userId,
                                                        categoryId: transaction.type == 'income'
                                                            ? transaction.categoryId
                                                            : result.categoryId!,
                                                        type: transaction.type,
                                                        description: result.description,
                                                        amount: result.amount,
                                                        dueDate: transaction.type == 'expense'
                                                            ? result.mainDate
                                                            : null,
                                                        receivedDate: transaction.type == 'income'
                                                            ? result.mainDate
                                                            : null,
                                                        status: result.status,
                                                        paidAt: result.paidAt,
                                                        createdAt: transaction.createdAt,
                                                        isInstallment: transaction.isInstallment,
                                                        installmentGroupId: transaction.installmentGroupId,
                                                        installmentNumber: transaction.installmentNumber,
                                                        installmentTotal: transaction.installmentTotal,
                                                        installmentFullAmount: transaction.installmentFullAmount,
                                                      );

                                                  _refreshFinancialData(activeUser.id);

                                                  if (!mounted) return;

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Transação editada com sucesso'),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!mounted) return;

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Erro ao editar transação: $e'),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _statusIcon(effectiveStatus),
                                                color: _statusColor(effectiveStatus),
                                              ),
                                              onPressed: transaction.type == 'expense'
                                                  ? () async {
                                                      final result =
                                                          await _showChangeStatusDialog(
                                                        currentStatus: transaction.status,
                                                        currentPaidAt: transaction.paidAt,
                                                        type: transaction.type,
                                                      );

                                                      if (result == null) return;

                                                      await ref
                                                          .read(transactionControllerProvider)
                                                          .updateStatus(
                                                            transactionId: transaction.id,
                                                            status: result.status,
                                                            paidAt: result.paidAt,
                                                          );

                                                      _refreshFinancialData(activeUser.id);
                                                    }
                                                  : null,
                                            ),
                                            if (transaction.type == 'expense' &&
                                                !transaction.isInstallment)
                                              IconButton(
                                                tooltip: 'Copiar para próximo mês',
                                                icon: const Icon(Icons.copy_outlined),
                                                onPressed: () async {
                                                  final suggestedDate = ref
                                                      .read(transactionControllerProvider)
                                                      .suggestedNextMonthDate(transaction);

                                                  final result = await Navigator.of(context)
                                                      .push<ReuseTransactionPageResult>(
                                                    MaterialPageRoute(
                                                      builder: (_) => ReuseTransactionPage(
                                                        transaction: transaction,
                                                        suggestedDate: suggestedDate,
                                                      ),
                                                    ),
                                                  );

                                                  if (result == null) return;

                                                  try {
                                                    await ref
                                                        .read(transactionControllerProvider)
                                                        .reuseTransactionNextMonth(
                                                          transaction: transaction,
                                                          amount: result.amount,
                                                          nextDate: result.nextDate,
                                                        );

                                                    _refreshFinancialData(activeUser.id);

                                                    if (!mounted) return;

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Transação copiada com sucesso'),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!mounted) return;

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Erro ao copiar transação: $e'),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: () async {
                                                final confirmed =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return AlertDialog(
                                                      title: const Text('Excluir transação'),
                                                      content: const Text(
                                                        'Tem certeza que deseja excluir esta transação?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(dialogContext).pop(false),
                                                          child: const Text('Cancelar'),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.of(dialogContext).pop(true),
                                                          child: const Text('Excluir'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                if (confirmed != true) return;

                                                await ref
                                                    .read(transactionControllerProvider)
                                                    .deleteTransaction(transaction.id);

                                                _refreshFinancialData(activeUser.id);
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
                    ),
                  );
                },
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

class _TransactionMonthSelector extends ConsumerWidget {
  final DateTime selectedMonth;

  const _TransactionMonthSelector({
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month - 1);
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            _monthLabel(selectedMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month + 1);
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

class _StatusDialogResult {
  final String status;
  final DateTime? paidAt;

  const _StatusDialogResult({
    required this.status,
    required this.paidAt,
  });
}