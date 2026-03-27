import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../../domain/entities/credit_card_debt.dart';
import '../controllers/credit_card_debt_provider.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dívidas'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Nenhum usuário ativo'),
            );
          }

          final debtsAsync = ref.watch(creditCardDebtsProvider(user.id));

          return debtsAsync.when(
            data: (debts) {
              if (debts.isEmpty) {
                return const Center(
                  child: Text('Nenhuma dívida ativa'),
                );
              }

              final totalMonthlyInstallments = debts.fold<double>(
                0,
                (sum, debt) => sum + debt.installmentAmount,
              );

              final totalRemaining = debts.fold<double>(
                0,
                (sum, debt) => sum + debt.remainingAmount,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DebtsSummaryCard(
                      totalMonthlyInstallments: totalMonthlyInstallments,
                      totalRemaining: totalRemaining,
                      activeDebtsCount: debts.length,
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeader(
                      title: 'Compras parceladas em aberto',
                      subtitle:
                          'Tudo que ainda está sendo pago, independente do mês em que a compra foi feita.',
                    ),
                    const SizedBox(height: 12),
                    ...debts.map(
                      (debt) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DebtCard(debt: debt),
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
              child: Text('Erro ao carregar dívidas: $error'),
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

class _DebtsSummaryCard extends StatelessWidget {
  final double totalMonthlyInstallments;
  final double totalRemaining;
  final int activeDebtsCount;

  const _DebtsSummaryCard({
    required this.totalMonthlyInstallments,
    required this.totalRemaining,
    required this.activeDebtsCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryInfo(
                      title: 'Total das parcelas',
                      value: _formatCurrency(totalMonthlyInstallments),
                      subtitle: 'Soma mensal das compras parceladas',
                    ),
                    const SizedBox(height: 18),
                    _SummaryInfo(
                      title: 'Valor restante',
                      value: _formatCurrency(totalRemaining),
                      subtitle: 'Total que ainda falta quitar',
                    ),
                    const SizedBox(height: 18),
                    _SummaryInfo(
                      title: 'Compras em aberto',
                      value: '$activeDebtsCount',
                      subtitle: 'Quantidade de compras parceladas ativas',
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SummaryInfo(
                      title: 'Total das parcelas',
                      value: _formatCurrency(totalMonthlyInstallments),
                      subtitle: 'Soma mensal das compras parceladas',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _SummaryInfo(
                      title: 'Valor restante',
                      value: _formatCurrency(totalRemaining),
                      subtitle: 'Total que ainda falta quitar',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _SummaryInfo(
                      title: 'Compras em aberto',
                      value: '$activeDebtsCount',
                      subtitle: 'Quantidade de compras parceladas ativas',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _SummaryInfo extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SummaryInfo({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final CreditCardDebt debt;

  const _DebtCard({
    required this.debt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DebtTopRow(debt: debt),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 820;

                  if (isCompact) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DebtMetric(
                                title: 'Valor total',
                                value: _formatCurrency(debt.totalAmount),
                              ),
                            ),
                            Expanded(
                              child: _DebtMetric(
                                title: 'Valor da parcela',
                                value: _formatCurrency(debt.installmentAmount),
                                highlight: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DebtMetric(
                                title: 'Parcelas',
                                value: '${debt.totalInstallments}',
                              ),
                            ),
                            Expanded(
                              child: _DebtMetric(
                                title: 'Pagas',
                                value: '${debt.paidInstallments}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DebtMetric(
                                title: 'Restantes',
                                value: '${debt.remainingInstallments}',
                              ),
                            ),
                            Expanded(
                              child: _DebtMetric(
                                title: 'Valor restante',
                                value: _formatCurrency(debt.remainingAmount),
                                highlight: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DebtMetric(
                          title: 'Valor total',
                          value: _formatCurrency(debt.totalAmount),
                        ),
                      ),
                      Expanded(
                        child: _DebtMetric(
                          title: 'Valor da parcela',
                          value: _formatCurrency(debt.installmentAmount),
                          highlight: true,
                        ),
                      ),
                      Expanded(
                        child: _DebtMetric(
                          title: 'Parcelas',
                          value: '${debt.totalInstallments}',
                        ),
                      ),
                      Expanded(
                        child: _DebtMetric(
                          title: 'Pagas',
                          value: '${debt.paidInstallments}',
                        ),
                      ),
                      Expanded(
                        child: _DebtMetric(
                          title: 'Restantes',
                          value: '${debt.remainingInstallments}',
                        ),
                      ),
                      Expanded(
                        child: _DebtMetric(
                          title: 'Valor restante',
                          value: _formatCurrency(debt.remainingAmount),
                          highlight: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: debt.totalInstallments == 0
                  ? 0
                  : debt.paidInstallments / debt.totalInstallments,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              '${debt.paidInstallments} de ${debt.totalInstallments} parcelas pagas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _DebtTopRow extends StatelessWidget {
  final CreditCardDebt debt;

  const _DebtTopRow({
    required this.debt,
  });

  bool _looksLikeServiceOrBill(String text) {
    final value = text.toLowerCase();

    const keywords = [
      'internet',
      'energia',
      'luz',
      'água',
      'agua',
      'telefone',
      'celular',
      'aluguel',
      'condomínio',
      'condominio',
      'seguro',
      'fatura',
      'mensalidade',
      'escola',
      'faculdade',
      'academia',
      'streaming',
      'netflix',
      'spotify',
      'conta',
      'boleto',
    ];

    return keywords.any(value.contains);
  }

  @override
  Widget build(BuildContext context) {
    final store = debt.store.trim();
    final description = debt.description.trim();

    final hasStore = store.isNotEmpty;
    final isSame = store.toLowerCase() == description.toLowerCase();
    final showDescription = hasStore && !isSame;

    final icon = _looksLikeServiceOrBill('$store $description')
        ? Icons.receipt_long_outlined
        : Icons.shopping_bag_outlined;

    final title = hasStore && !isSame ? store : description;

    return Wrap(
      spacing: 14,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon),
        ),
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ],
          ),
        ),
        _StatusPill(
          label: debt.remainingInstallments == 0 ? 'Quitada' : 'Em aberto',
          isDone: debt.remainingInstallments == 0,
        ),
      ],
    );
  }
}

class _DebtMetric extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _DebtMetric({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = highlight
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: valueStyle,
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isDone;

  const _StatusPill({
    required this.label,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}