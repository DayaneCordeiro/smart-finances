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
  bool _isPaid = false;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );

    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
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
            transactionDate: _selectedDate,
            isPaid: _isPaid,
          );

      _descriptionController.clear();
      _amountController.clear();
      _selectedCategoryId = null;
      _isPaid = false;
      _selectedDate = DateTime.now();

      ref.invalidate(transactionsProvider(userId));

      if (!mounted) return;

      setState(() {});

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
                                'Data: ${_formatDate(_selectedDate)}',
                              ),
                              trailing: OutlinedButton(
                                onPressed: _pickDate,
                                child: const Text('Escolher data'),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _isPaid,
                              onChanged: (value) {
                                setState(() => _isPaid = value);
                              },
                              title: const Text('Marcar como pago'),
                              subtitle: const Text(
                                'Se marcar, a data de pagamento será salva automaticamente',
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
                                    '${transaction.type == 'income' ? 'Receita' : 'Despesa'} • ${_formatCurrency(transaction.amount)} • ${_formatDate(transaction.transactionDate)}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          transaction.isPaid
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: transaction.isPaid
                                              ? Colors.green
                                              : Colors.white54,
                                        ),
                                        onPressed: () async {
                                          await ref
                                              .read(transactionControllerProvider)
                                              .togglePaidStatus(
                                                transactionId: transaction.id,
                                                isPaid: !transaction.isPaid,
                                              );

                                          ref.invalidate(
                                            transactionsProvider(activeUser.id),
                                          );
                                        },
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
}