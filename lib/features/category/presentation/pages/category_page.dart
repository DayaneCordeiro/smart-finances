import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../controllers/category_providers.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  final _nameController = TextEditingController();
  String _selectedType = 'expense';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _refreshDashboard(String userId) {
    ref.invalidate(filteredTransactionsByMonthProvider(userId));
    ref.invalidate(monthlySummaryProvider(userId));
    ref.invalidate(dashboardActiveUserSummaryProvider);
  }

  Future<void> _saveCategory(String userId) async {
    setState(() => _isSaving = true);

    try {
      await ref.read(categoryControllerProvider).createCategory(
            userId: userId,
            name: _nameController.text,
            type: _selectedType,
          );

      _nameController.clear();
      ref.invalidate(categoriesProvider(userId));
      _refreshDashboard(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria criada com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar categoria: $e')),
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
        title: const Text('Categorias'),
        backgroundColor: Colors.transparent,
      ),
      body: activeUserAsync.when(
        data: (activeUser) {
          if (activeUser == null) {
            return const Center(child: Text('Nenhum usuário ativo'));
          }

          final categoriesAsync = ref.watch(categoriesProvider(activeUser.id));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da categoria',
                          ),
                        ),
                        const SizedBox(height: 16),
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
                            setState(() => _selectedType = value.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _saveCategory(activeUser.id),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar categoria'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma categoria cadastrada'),
                        );
                      }

                      return ListView.separated(
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final category = categories[index];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  category.type == 'income'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                ),
                              ),
                              title: Text(category.name),
                              subtitle: Text(
                                category.type == 'income'
                                    ? 'Receita'
                                    : 'Despesa',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(categoryControllerProvider)
                                      .deleteCategory(category.id);

                                  ref.invalidate(categoriesProvider(activeUser.id));
                                  _refreshDashboard(activeUser.id);
                                },
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
                      child: Text('Erro ao carregar categorias: $error'),
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