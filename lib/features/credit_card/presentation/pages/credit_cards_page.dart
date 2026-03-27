import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/credit_card_providers.dart';
import 'edit_credit_card_page.dart';

class CreditCardsPage extends ConsumerStatefulWidget {
  const CreditCardsPage({super.key});

  @override
  ConsumerState<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends ConsumerState<CreditCardsPage> {
  final _nameController = TextEditingController();
  final _closingDayController = TextEditingController();
  final _dueDayController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _saveCard(String userId) async {
    final name = _nameController.text.trim();
    final closingDay = int.tryParse(_closingDayController.text.trim());
    final dueDay = int.tryParse(_dueDayController.text.trim());

    if (name.isEmpty) {
      _showMessage('Informe o nome do cartão');
      return;
    }

    if (closingDay == null || closingDay < 1 || closingDay > 31) {
      _showMessage('Informe um dia de fechamento válido');
      return;
    }

    if (dueDay == null || dueDay < 1 || dueDay > 31) {
      _showMessage('Informe um dia de vencimento válido');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(creditCardActionsProvider).create(
            userId: userId,
            name: name,
            closingDay: closingDay,
            dueDay: dueDay,
          );

      _nameController.clear();
      _closingDayController.clear();
      _dueDayController.clear();

      ref.invalidate(creditCardsProvider(userId));

      if (!mounted) return;
      _showMessage('Cartão cadastrado com sucesso');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erro ao cadastrar cartão: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editCard({
    required String userId,
    required dynamic card,
  }) async {
    final result = await Navigator.of(context).push<EditCreditCardResult>(
      MaterialPageRoute(
        builder: (_) => EditCreditCardPage(card: card),
      ),
    );

    if (result == null) return;

    try {
      await ref.read(creditCardActionsProvider).update(
            card: card,
            name: result.name,
            closingDay: result.closingDay,
            dueDay: result.dueDay,
          );

      ref.invalidate(creditCardsProvider(userId));

      if (!mounted) return;
      _showMessage('Cartão atualizado com sucesso');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erro ao atualizar cartão: $e');
    }
  }

  Future<void> _deleteCard({
    required String userId,
    required dynamic card,
  }) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir cartão'),
          content: Text(
            'Tem certeza que deseja excluir o cartão ${card.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(creditCardActionsProvider).delete(card.id);

      ref.invalidate(creditCardsProvider(userId));

      if (!mounted) return;
      _showMessage('Cartão excluído com sucesso');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUserAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões de crédito'),
      ),
      body: activeUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Nenhum usuário ativo'),
            );
          }

          final cardsAsync = ref.watch(creditCardsProvider(user.id));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Novo cartão',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do cartão',
                            hintText: 'Ex.: Nubank',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _closingDayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Fechamento',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _dueDayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Vencimento',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _isSaving ? null : () => _saveCard(user.id),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar cartão'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: cardsAsync.when(
                    data: (cards) {
                      if (cards.isEmpty) {
                        return const Center(
                          child: Text('Nenhum cartão cadastrado'),
                        );
                      }

                      return ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final card = cards[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.credit_card),
                              ),
                              title: Text(card.name),
                              subtitle: Text(
                                'Fecha dia ${card.closingDay} • Vence dia ${card.dueDay}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => _editCard(
                                      userId: user.id,
                                      card: card,
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Excluir',
                                    onPressed: () => _deleteCard(
                                      userId: user.id,
                                      card: card,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
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
                      child: Text('Erro ao carregar cartões: $error'),
                    ),
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
          child: Text('Erro ao carregar usuário: $error'),
        ),
      ),
    );
  }
}