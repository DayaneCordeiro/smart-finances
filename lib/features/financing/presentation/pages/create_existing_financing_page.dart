import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/financing_providers.dart';

class CreateExistingFinancingPage extends ConsumerStatefulWidget {
  const CreateExistingFinancingPage({super.key});

  @override
  ConsumerState<CreateExistingFinancingPage> createState() =>
      _CreateExistingFinancingPageState();
}

class _CreateExistingFinancingPageState
    extends ConsumerState<CreateExistingFinancingPage> {
  final _nameController = TextEditingController();
  final _assetController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalController = TextEditingController();
  final _installmentsController = TextEditingController();
  final _alreadyPaidController = TextEditingController();

  DateTime _firstDueDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _assetController.dispose();
    _descriptionController.dispose();
    _totalController.dispose();
    _installmentsController.dispose();
    _alreadyPaidController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _firstDueDate,
    );

    if (selected != null) {
      setState(() => _firstDueDate = selected);
    }
  }

  Future<void> _save(String userId) async {
    final totalAmount =
        double.tryParse(_totalController.text.replaceAll(',', '.'));
    final totalInstallments =
        int.tryParse(_installmentsController.text.trim());
    final alreadyPaid =
        int.tryParse(_alreadyPaidController.text.trim());

    if (totalAmount == null || totalAmount <= 0) {
      _showMessage('Informe o valor total');
      return;
    }

    if (totalInstallments == null || totalInstallments <= 0) {
      _showMessage('Informe a quantidade de parcelas');
      return;
    }

    if (alreadyPaid == null || alreadyPaid < 0) {
      _showMessage('Informe quantas parcelas já foram pagas');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(financingActionsProvider).createExistingFinancing(
            userId: userId,
            name: _nameController.text,
            assetName: _assetController.text,
            description: _descriptionController.text,
            totalAmount: totalAmount,
            totalInstallments: totalInstallments,
            alreadyPaidInstallments: alreadyPaid,
            firstDueDate: _firstDueDate,
          );

      ref.invalidate(financingsProvider(userId));

      if (!mounted) return;
      _showMessage('Financiamento em andamento cadastrado com sucesso');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erro ao salvar financiamento: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
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

  @override
  Widget build(BuildContext context) {
    final activeUserAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financiamento em andamento'),
      ),
      body: activeUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Nenhum usuário ativo'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do financiamento',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _assetController,
                      decoration: const InputDecoration(
                        labelText: 'Bem financiado',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _totalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor total com juros',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade total de parcelas',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _alreadyPaidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Parcelas já pagas',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Primeiro vencimento: ${_formatDate(_firstDueDate)}',
                      ),
                      trailing: OutlinedButton(
                        onPressed: _pickDate,
                        child: const Text('Escolher data'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : () => _save(user.id),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar financiamento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro ao carregar usuário: $error'),
        ),
      ),
    );
  }
}