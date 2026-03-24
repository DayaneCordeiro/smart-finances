import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../controllers/user_providers.dart';
import '../widgets/user_card.dart';
import 'create_user_page.dart';

class UserListPage extends ConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final activeUserAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfis do tablet'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateUserPage()),
          );
        },
        label: const Text('Novo usuário'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: usersAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return const Center(
                child: Text('Nenhum usuário cadastrado'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                activeUserAsync.when(
                  data: (activeUser) => Text(
                    activeUser != null
                        ? 'Usuário ativo: ${activeUser.name}'
                        : 'Nenhum usuário ativo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return UserCard(
                        user: user,
                        onTap: () async {
                          await ref
                              .read(userControllerProvider)
                              .setActiveUser(user.id);

                          ref.invalidate(usersProvider);
                          ref.invalidate(activeUserProvider);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${user.name} agora é o perfil ativo'),
                            ),
                          );

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const DashboardPage(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Erro: $error'),
          ),
        ),
      ),
    );
  }
}