import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/controllers/category_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/credit_card_debt_provider.dart';
import '../controllers/credit_card_providers.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';

class CreateExistingDebtPage extends ConsumerStatefulWidget {
  const CreateExistingDebtPage({super.key});

  @override
  ConsumerState<CreateExistingDebtPage> createState() =>
      _CreateExistingDebtPageState();
}

class _CreateExistingDebtPageState
    extends ConsumerState<CreateExistingDebtPage> {
  final _storeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _totalInstallmentsController = TextEditingController();
  final _paidInstallmentsController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCreditCardId;
  DateTime _nextInstallmentDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalAmountController.addListener(_recalculateInstallmentAmount);
    _totalInstallmentsController.addListener(_recalculateInstallmentAmount);
  }

  @override
  void dispose() {
    _totalAmountController.removeListener(_recalculateInstallmentAmount);
    _totalInstallmentsController.removeListener(_recalculateInstallmentAmount);

    _storeController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _installmentAmountController.dispose();
    _totalInstallmentsController.dispose();
    _paidInstallmentsController.dispose();
    super.dispose();
  }

  void _recalculateInstallmentAmount() {
    final totalAmount =
        double.tryParse(_totalAmountController.text.replaceAll(',', '.'));
    final totalInstallments =
        int.tryParse(_totalInstallmentsController.text.trim());

    if (totalAmount == null ||
        totalAmount <= 0 ||
        totalInstallments == null ||
        totalInstallments <= 0) {
      if (_installmentAmountController.text.isNotEmpty) {
        _installmentAmountController.text = '';
      }
      return;
    }

    final rawInstallment = totalAmount / totalInstallments;
    final roundedUpInstallment = _roundUpToCents(rawInstallment);
    final formatted = roundedUpInstallment.toStringAsFixed(2);

    if (_installmentAmountController.text != formatted) {
      _installmentAmountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  double _roundUpToCents(double value) {
    return (value * 100).ceil() / 100;
  }

  Future<void> _pickNextInstallmentDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _nextInstallmentDate,
    );

    if (picked != null) {
      setState(() => _nextInstallmentDate = picked);
    }
  }

  void _refreshAll(String userId) {
    ref.invalidate(transactionsProvider(userId));
    ref.invalidate(filteredTransactionsByMonthProvider(userId));
    ref.invalidate(monthlySummaryProvider(userId));
    ref.invalidate(dashboardActiveUserSummaryProvider);
    ref.invalidate(creditCardStatementsProvider(userId));
    ref.invalidate(creditCardDebtsProvider(userId));
  }

  Future<void> _saveExistingDebt(String userId) async {
    final totalAmount =
        double.tryParse(_totalAmountController.text.replaceAll(',', '.'));
    final installmentAmount =
        double.tryParse(_installmentAmountController.text.replaceAll(',', '.'));
    final totalInstallments =
        int.tryParse(_totalInstallmentsController.text.trim());
    final paidInstallments =
        int.tryParse(_paidInstallmentsController.text.trim());

    if (_storeController.text.trim().isEmpty) {
      _showError('Informe a loja');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Informe a descrição');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Selecione a categoria');
      return;
    }

    if (_selectedCreditCardId == null) {
      _showError('Selecione o cartão');
      return;
    }

    if (totalAmount == null || totalAmount <= 0) {
      _showError('Informe um valor total válido');
      return;
    }

    if (installmentAmount == null || installmentAmount <= 0) {
      _showError('Informe um valor de parcela válido');
      return;
    }

    if (totalInstallments == null || totalInstallments < 2) {
      _showError('Informe a quantidade total de parcelas');
      return;
    }

    if (paidInstallments == null ||
        paidInstallments < 0 ||
        paidInstallments >= totalInstallments) {
      _showError('Informe quantas parcelas já foram pagas');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(transactionControllerProvider).createExistingDebt(
            userId: userId,
            categoryId: _selectedCategoryId!,
            storeName: _storeController.text,
            description: _descriptionController.text,
            totalAmount: totalAmount,
            installmentAmount: installmentAmount,
            totalInstallments: totalInstallments,
            paidInstallments: paidInstallments,
            nextInstallmentDate: _nextInstallmentDate,
            creditCardId: _selectedCreditCardId!,
          );

      _refreshAll(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dívida em andamento cadastrada com sucesso'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao salvar dívida: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final userAsync = ref.watch(activeUserProvider);

    final previewTotalAmount =
        double.tryParse(_totalAmountController.text.replaceAll(',', '.'));
    final previewInstallmentAmount =
        double.tryParse(_installmentAmountController.text.replaceAll(',', '.'));
    final previewTotalInstallments =
        int.tryParse(_totalInstallmentsController.text.trim());
    final previewPaidInstallments =
        int.tryParse(_paidInstallmentsController.text.trim()) ?? 0;

    final previewRemainingInstallments =
        previewTotalInstallments != null && previewTotalInstallments > 0
            ? math.max(0, previewTotalInstallments - previewPaidInstallments)
            : null;

    final previewRemainingAmount = (previewRemainingInstallments != null &&
            previewInstallmentAmount != null)
        ? previewRemainingInstallments * previewInstallmentAmount
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar dívida em andamento'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Nenhum usuário ativo'));
          }

          final categoriesAsync = ref.watch(expenseCategoriesProvider(user.id));
          final cardsAsync = ref.watch(creditCardsProvider(user.id));

          return categoriesAsync.when(
            data: (categories) {
              final expenseCategories = categories
                  .where((category) => category.type == 'expense')
                  .toList();

              return cardsAsync.when(
                data: (cards) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compra parcelada já em andamento',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cadastre só o que ainda falta pagar. O sistema vai considerar as parcelas já pagas e gerar apenas as parcelas futuras.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _storeController,
                              decoration: const InputDecoration(
                                labelText: 'Loja',
                                hintText: 'Ex.: Magalu',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                                hintText: 'Ex.: Tablet',
                              ),
                            ),
                            const SizedBox(height: 16),
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
                            DropdownButtonFormField<String>(
                              value: _selectedCreditCardId,
                              decoration: const InputDecoration(
                                labelText: 'Cartão',
                              ),
                              items: cards.map((card) {
                                return DropdownMenuItem(
                                  value: card.id,
                                  child: Text(card.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCreditCardId = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _totalAmountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Valor total da compra',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _totalInstallmentsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Parcelas totais',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _paidInstallmentsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Já pagas',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _installmentAmountController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Valor da parcela',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Data da próxima parcela: ${_formatDate(_nextInstallmentDate)}',
                              ),
                              trailing: OutlinedButton(
                                onPressed: _pickNextInstallmentDate,
                                child: const Text('Escolher data'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Prévia da dívida',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    _PreviewRow(
                                      label: 'Valor total',
                                      value: previewTotalAmount != null
                                          ? _formatCurrency(previewTotalAmount)
                                          : '-',
                                    ),
                                    const SizedBox(height: 8),
                                    _PreviewRow(
                                      label: 'Valor da parcela',
                                      value: previewInstallmentAmount != null
                                          ? _formatCurrency(
                                              previewInstallmentAmount,
                                            )
                                          : '-',
                                    ),
                                    const SizedBox(height: 8),
                                    _PreviewRow(
                                      label: 'Parcelas restantes',
                                      value: previewRemainingInstallments != null
                                          ? '$previewRemainingInstallments'
                                          : '-',
                                    ),
                                    const SizedBox(height: 8),
                                    _PreviewRow(
                                      label: 'Valor restante',
                                      value: previewRemainingAmount != null
                                          ? _formatCurrency(
                                              previewRemainingAmount,
                                            )
                                          : '-',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => _saveExistingDebt(user.id),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Salvar dívida em andamento'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Erro ao carregar cartões: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Erro ao carregar categorias: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Erro ao carregar usuário: $error')),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}