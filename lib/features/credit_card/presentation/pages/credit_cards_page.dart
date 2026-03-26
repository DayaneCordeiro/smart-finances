import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/credit_card_providers.dart';

class CreditCardsPage extends ConsumerStatefulWidget {
  const CreditCardsPage({super.key});

  @override
  ConsumerState<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends ConsumerState<CreditCardsPage> {
  final _nameController = TextEditingController();
  final _closingDayController = TextEditingController();
  final _dueDayController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _saveCard(String userId) async {
    final closingDay = int.tryParse(_closingDayController.text.trim());
    final dueDay = int.tryParse(_dueDayController.text.trim());

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do cartão')),
      );
      return;
    }

    if (closingDay == null || dueDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe dias válidos')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(creditCardControllerProvider).createCard(
            userId: userId,
            name: _nameController.text,
            closingDay: closingDay,
            dueDay: dueDay,
          );

      ref.invalidate(creditCardsProvider(userId));

      _nameController.clear();
      _closingDayController.clear();
      _dueDayController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cartão cadastrado com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar cartão: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUserAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões de crédito'),
      ),
      body: activeUserAsync.when(
        data: (activeUser) {
          if (activeUser == null) {
            return const Center(child: Text('Nenhum usuário ativo'));
          }

          final cardsAsync = ref.watch(creditCardsProvider(activeUser.id));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novo cartão',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
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
                        TextField(
                          controller: _closingDayController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dia de fechamento',
                            hintText: 'Ex.: 20',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _dueDayController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dia de vencimento',
                            hintText: 'Ex.: 27',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _saveCard(activeUser.id),
                            icon: const Icon(Icons.save_outlined),
                            label: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
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
                const SizedBox(height: 20),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final card = cards[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.credit_card),
                              ),
                              title: Text(card.name),
                              subtitle: Text(
                                'Fechamento: dia ${card.closingDay} • Vencimento: dia ${card.dueDay}',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro ao carregar usuário ativo: $error'),
        ),
      ),
    );
  }
}