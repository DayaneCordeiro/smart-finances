import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/controllers/category_providers.dart';
import '../../../credit_card/presentation/controllers/credit_card_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../domain/entities/finance_transaction.dart';
import '../controllers/transaction_providers.dart';
import '../widgets/transaction_form_card.dart';
import '../widgets/transaction_list_card.dart';
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
  String? _selectedCreditCardId;
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
    ref.invalidate(creditCardStatementsProvider(userId));
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
              creditCardId: null,
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
              creditCardId: _selectedCreditCardId,
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
              creditCardId: _selectedCreditCardId,
            );
      }

      _descriptionController.clear();
      _amountController.clear();

      setState(() {
        _selectedCategoryId = null;
        _selectedCreditCardId = null;
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
                                        setModalState(() => tempPaidAt = selected);
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
          final creditCardsAsync = ref.watch(creditCardsProvider(activeUser.id));
          final transactionsAsync =
              ref.watch(filteredTransactionsByMonthProvider(activeUser.id));

          return categoriesAsync.when(
            data: (categories) {
              return creditCardsAsync.when(
                data: (creditCards) {
                  final expenseCategories = categories
                      .where((category) => category.type == 'expense')
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _TransactionMonthSelector(
                              selectedMonth: selectedMonth,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 1100;

                              if (isCompact) {
                                return Column(
                                  children: [
                                    Expanded(
                                      child: _buildTransactionList(
                                        context: context,
                                        activeUserId: activeUser.id,
                                        categories: categories,
                                        transactionsAsync: transactionsAsync,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: _buildTransactionForm(
                                        activeUserId: activeUser.id,
                                        expenseCategories: expenseCategories,
                                        creditCards: creditCards,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildTransactionList(
                                      context: context,
                                      activeUserId: activeUser.id,
                                      categories: categories,
                                      transactionsAsync: transactionsAsync,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: _buildTransactionForm(
                                      activeUserId: activeUser.id,
                                      expenseCategories: expenseCategories,
                                      creditCards: creditCards,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Erro ao carregar cartões: $error'),
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

  Widget _buildTransactionList({
    required BuildContext context,
    required String activeUserId,
    required List<dynamic> categories,
    required AsyncValue<List<FinanceTransaction>> transactionsAsync,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transações do mês',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma transação neste mês'),
                    );
                  }

                  return ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final effectiveStatus =
                          _effectiveStatusForDisplay(transaction);

                      return TransactionListCard(
                        transaction: transaction,
                        effectiveStatus: effectiveStatus,
                        onEdit: () async {
                          final result = await Navigator.of(context)
                              .push<EditTransactionResult>(
                            MaterialPageRoute(
                              builder: (_) => EditTransactionPage(
                                transaction: transaction,
                                categories: categories.cast(),
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
                                  installmentGroupId:
                                      transaction.installmentGroupId,
                                  installmentNumber:
                                      transaction.installmentNumber,
                                  installmentTotal: transaction.installmentTotal,
                                  installmentFullAmount:
                                      transaction.installmentFullAmount,
                                  creditCardId: transaction.creditCardId,
                                );

                            _refreshFinancialData(activeUserId);

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
                        onChangeStatus: transaction.type == 'expense'
                            ? () async {
                                final result = await _showChangeStatusDialog(
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

                                _refreshFinancialData(activeUserId);
                              }
                            : null,
                        onCopyNextMonth: transaction.type == 'expense' &&
                                !transaction.isInstallment
                            ? () async {
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

                                  _refreshFinancialData(activeUserId);

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Transação copiada com sucesso',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Erro ao copiar transação: $e'),
                                    ),
                                  );
                                }
                              }
                            : null,
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
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

                          _refreshFinancialData(activeUserId);
                        },
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
  }

  Widget _buildTransactionForm({
    required String activeUserId,
    required List<dynamic> expenseCategories,
    required List<dynamic> creditCards,
  }) {
    return Card(
      child: TransactionFormCard(
        selectedType: _selectedType,
        descriptionController: _descriptionController,
        amountController: _amountController,
        installmentCountController: _installmentCountController,
        expenseCategories: expenseCategories.cast(),
        creditCards: creditCards.cast(),
        selectedCategoryId: _selectedCategoryId,
        onCategoryChanged: (value) {
          setState(() => _selectedCategoryId = value);
        },
        selectedCreditCardId: _selectedCreditCardId,
        onCreditCardChanged: (value) {
          setState(() => _selectedCreditCardId = value);
        },
        selectedStatus: _selectedStatus,
        onStatusChanged: (value) {
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
        markAsPaid: _markAsPaid,
        onMarkAsPaidChanged: _syncStatusWithSwitch,
        isInstallment: _isInstallment,
        onInstallmentChanged: (value) {
          setState(() {
            _isInstallment = value;

            if (value) {
              _selectedStatus = 'pending';
              _markAsPaid = false;
              _paidAtDate = null;
            }
          });
        },
        mainDate: _mainDate,
        onPickMainDate: _pickMainDate,
        paidAtDate: _paidAtDate,
        onPickPaidAtDate: _pickPaidAtDate,
        onClearPaidAt: () {
          setState(() => _paidAtDate = null);
        },
        isSaving: _isSaving,
        onSave: () => _saveTransaction(activeUserId),
        onTypeChanged: (value) {
          setState(() {
            _selectedType = value.first;
            _selectedCategoryId = null;
            _selectedCreditCardId = null;
            _selectedStatus = 'pending';
            _markAsPaid = false;
            _paidAtDate = null;
            _isInstallment = false;
            _mainDate = DateTime.now();
          });
        },
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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