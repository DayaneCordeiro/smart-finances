import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/financing_providers.dart';

class CreateFinancingPage extends ConsumerStatefulWidget {
  const CreateFinancingPage({super.key});

  @override
  ConsumerState<CreateFinancingPage> createState() =>
      _CreateFinancingPageState();
}

class _CreateFinancingPageState extends ConsumerState<CreateFinancingPage> {
  final _nameController = TextEditingController();
  final _assetController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalController = TextEditingController();
  final _installmentsController = TextEditingController();

  DateTime _firstDueDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _assetController.dispose();
    _descriptionController.dispose();
    _totalController.dispose();
    _installmentsController.dispose();
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

    if (totalAmount == null || totalAmount <= 0) {
      _showMessage('Informe o valor total');
      return;
    }

    if (totalInstallments == null || totalInstallments <= 0) {
      _showMessage('Informe a quantidade de parcelas');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(financingActionsProvider).createNewFinancing(
            userId: userId,
            name: _nameController.text,
            assetName: _assetController.text,
            description: _descriptionController.text,
            totalAmount: totalAmount,
            totalInstallments: totalInstallments,
            firstDueDate: _firstDueDate,
          );

      ref.invalidate(financingsProvider(userId));

      if (!mounted) return;
      _showMessage('Financiamento criado com sucesso');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erro ao criar financiamento: $e');
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
        title: const Text('Novo financiamento'),
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
                        hintText: 'Ex.: Financiamento carro',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _assetController,
                      decoration: const InputDecoration(
                        labelText: 'Bem financiado',
                        hintText: 'Ex.: HB20, Onix, Moto',
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
                        labelText: 'Quantidade de parcelas',
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