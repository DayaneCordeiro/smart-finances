import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/user/presentation/controllers/user_providers.dart';
import '../features/user/presentation/pages/create_user_page.dart';
import '../features/user/presentation/pages/user_list_page.dart';

class AppWidget extends ConsumerWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Financeiro Tablet',
      theme: AppTheme.darkTheme,
      home: usersAsync.when(
        data: (users) => users.isEmpty
            ? const CreateUserPage()
            : const UserListPage(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Erro ao carregar usuários: $error'),
          ),
        ),
      ),
    );
  }
}