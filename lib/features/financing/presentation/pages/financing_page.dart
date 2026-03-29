import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/financing_providers.dart';
import 'create_existing_financing_page.dart';
import 'create_financing_page.dart';
import 'financing_details_page.dart';

class FinancingPage extends ConsumerWidget {
  const FinancingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financiamento'),
      ),
      body: activeUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Nenhum usuário ativo'),
            );
          }

          final financingsAsync = ref.watch(financingsProvider(user.id));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateFinancingPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Novo financiamento'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CreateExistingFinancingPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Cadastrar em andamento'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: financingsAsync.when(
                    data: (financings) {
                      if (financings.isEmpty) {
                        return const Center(
                          child: Text('Nenhum financiamento cadastrado'),
                        );
                      }

                      return ListView.separated(
                        itemCount: financings.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final financing = financings[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.directions_car_outlined),
                              ),
                              title: Text(financing.name),
                              subtitle: Text(financing.assetName),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FinancingDetailsPage(
                                      contract: financing,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erro ao carregar financiamentos: $error'),
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