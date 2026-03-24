import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/pages/category_page.dart';
import '../../../transaction/presentation/pages/transaction_page.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../../user/presentation/pages/user_list_page.dart';
import '../controllers/dashboard_providers.dart';
import '../widgets/month_mood_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserAsync = ref.watch(activeUserProvider);
    final summaryAsync = ref.watch(dashboardActiveUserSummaryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            const _DashboardSidebar(),
            Expanded(
              child: activeUserAsync.when(
                data: (activeUser) {
                  return summaryAsync.when(
                    data: (summary) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              runSpacing: 16,
                              spacing: 16,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Smart Finances',
                                      style: textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      activeUser != null
                                          ? 'Olá, ${activeUser.name}'
                                          : 'Nenhum usuário ativo',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const TransactionPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nova transação'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _MonthHighlightCard(
                              balance: summary?.balance ?? 0,
                            ),
                            const SizedBox(height: 20),
                            MonthMoodCard(
                              balance: summary?.balance ?? 0,
                              overdueCount: summary?.overdueCount ?? 0,
                            ),
                            const SizedBox(height: 20),
                            _SummaryCardsSection(summary: summary),
                            const SizedBox(height: 20),
                            _ChartsAndAlertsSection(summary: summary),
                            const SizedBox(height: 20),
                            const _QuickActionsSection(),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erro ao carregar resumo: $error'),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Erro ao carregar usuário ativo: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2F),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 22,
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart Finances',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            selected: true,
          ),
          _SidebarItem(
            icon: Icons.swap_horiz_outlined,
            title: 'Transações',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionPage()),
              );
            },
          ),
          _SidebarItem(
            icon: Icons.category_outlined,
            title: 'Categorias',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoryPage()),
              );
            },
          ),
          const _SidebarItem(
            icon: Icons.receipt_long_outlined,
            title: 'Dívidas',
          ),
          const _SidebarItem(
            icon: Icons.directions_car_outlined,
            title: 'Financiamento',
          ),
          const _SidebarItem(
            icon: Icons.pie_chart_outline,
            title: 'Relatórios',
          ),
          const _SidebarItem(
            icon: Icons.settings_outlined,
            title: 'Configurações',
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const UserListPage()),
              );
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('Trocar perfil'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Colors.white12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? const Color(0xFF25314F) : Colors.transparent;
    final fgColor = selected ? Colors.white : Colors.white70;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: fgColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthHighlightCard extends StatelessWidget {
  final double balance;

  const _MonthHighlightCard({
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF243B6B),
            Color(0xFF18233B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visão geral do mês',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _monthLabel(now),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sua central financeira com foco em receitas, despesas e controle mensal.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo atual',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  static String _formatCurrency(double value) {
    final isNegative = value < 0;
    final absValue = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return isNegative ? '-R\$ $absValue' : 'R\$ $absValue';
  }
}

class _SummaryCardsSection extends StatelessWidget {
  final dynamic summary;

  const _SummaryCardsSection({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Entradas',
          value: _formatCurrency(summary?.totalIncome ?? 0),
          subtitle: 'Receitas do mês',
          icon: Icons.arrow_downward_rounded,
        ),
        _SummaryCard(
          title: 'Saídas',
          value: _formatCurrency(summary?.totalExpense ?? 0),
          subtitle: 'Despesas do mês',
          icon: Icons.arrow_upward_rounded,
        ),
        _SummaryCard(
          title: 'Pendentes',
          value: _formatCurrency(summary?.pendingTotal ?? 0),
          subtitle: 'Itens pendentes ou atrasados',
          icon: Icons.schedule,
        ),
        _SummaryCard(
          title: 'Atrasados',
          value: '${summary?.overdueCount ?? 0}',
          subtitle: 'Lançamentos vencidos',
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.08),
                child: Icon(icon),
              ),
              const SizedBox(height: 18),
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
          ),
        ),
      ),
    );
  }
}

class _ChartsAndAlertsSection extends StatelessWidget {
  final dynamic summary;

  const _ChartsAndAlertsSection({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _FinancialOverviewCard(summary: summary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _AlertCard(
                title: 'Itens atrasados',
                description:
                    (summary?.overdueCount ?? 0) > 0
                        ? 'Você tem ${summary.overdueCount} item(ns) atrasado(s) neste mês.'
                        : 'Nenhum item atrasado neste mês.',
                icon: Icons.alarm,
              ),
              const SizedBox(height: 16),
              _AlertCard(
                title: 'Situação do saldo',
                description: (summary?.balance ?? 0) >= 0
                    ? 'Seu saldo do mês está positivo.'
                    : 'Seu saldo do mês está negativo.',
                icon: Icons.pie_chart_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialOverviewCard extends StatelessWidget {
  final dynamic summary;

  const _FinancialOverviewCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncome = summary?.totalIncome ?? 0.0;
    final totalExpense = summary?.totalExpense ?? 0.0;
    final balance = summary?.balance ?? 0.0;
    final paidOrReceived = summary?.paidOrReceivedTotal ?? 0.0;
    final pending = summary?.pendingTotal ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo financeiro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Visão consolidada do mês atual.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'Receitas', value: _formatCurrency(totalIncome)),
            const SizedBox(height: 12),
            _InfoRow(label: 'Despesas', value: _formatCurrency(totalExpense)),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Pago/Recebido',
              value: _formatCurrency(paidOrReceived),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Pendentes', value: _formatCurrency(pending)),
            const Divider(height: 32),
            _InfoRow(
              label: 'Saldo do mês',
              value: _formatCurrency(balance),
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final absValue = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return isNegative ? '-R\$ $absValue' : 'R\$ $absValue';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isHighlight
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _AlertCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.08),
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Nova receita'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Nova despesa'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoryPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Categorias'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}