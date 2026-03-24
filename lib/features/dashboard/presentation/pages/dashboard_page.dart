import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/controllers/user_providers.dart';
import '../../../user/presentation/pages/user_list_page.dart';
import '../widgets/month_mood_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserAsync = ref.watch(activeUserProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            const _DashboardSidebar(),
            Expanded(
              child: activeUserAsync.when(
                data: (activeUser) {
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
                              onPressed: () {},
                              icon: const Icon(Icons.add),
                              label: const Text('Nova transação'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _MonthHighlightCard(),
                        const SizedBox(height: 20),
                        const MonthMoodCard(balance: 250),
                        const SizedBox(height: 20),
                        const _SummaryCardsSection(),
                        const SizedBox(height: 20),
                        const _ChartsAndAlertsSection(),
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
          const _SidebarItem(
            icon: Icons.swap_horiz_outlined,
            title: 'Transações',
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
                MaterialPageRoute(
                  builder: (_) => const UserListPage(),
                ),
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

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.selected = false,
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
          onTap: () {},
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
  const _MonthHighlightCard();

  @override
  Widget build(BuildContext context) {
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visão geral do mês',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Março 2026',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sua central financeira com foco em gastos, dívidas e metas.',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo atual',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 6),
                Text(
                  'R\$ 0,00',
                  style: TextStyle(
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
}

class _SummaryCardsSection extends StatelessWidget {
  const _SummaryCardsSection();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Entradas',
          value: 'R\$ 0,00',
          subtitle: 'Receitas do mês',
          icon: Icons.arrow_downward_rounded,
        ),
        _SummaryCard(
          title: 'Saídas',
          value: 'R\$ 0,00',
          subtitle: 'Despesas do mês',
          icon: Icons.arrow_upward_rounded,
        ),
        _SummaryCard(
          title: 'Dívidas em aberto',
          value: 'R\$ 0,00',
          subtitle: 'Parcelas pendentes',
          icon: Icons.receipt_long_outlined,
        ),
        _SummaryCard(
          title: 'Alertas',
          value: '0',
          subtitle: 'Vencimentos próximos',
          icon: Icons.notifications_active_outlined,
        ),
      ],
    );
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
  const _ChartsAndAlertsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 2,
          child: _ExpensesChartPlaceholder(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: const [
              _AlertCard(
                title: 'Conta próxima do vencimento',
                description: 'Nenhuma conta cadastrada ainda.',
                icon: Icons.alarm,
              ),
              SizedBox(height: 16),
              _AlertCard(
                title: 'Limite do orçamento',
                description: 'Cadastre categorias para acompanhar metas.',
                icon: Icons.pie_chart_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpensesChartPlaceholder extends StatelessWidget {
  const _ExpensesChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução financeira',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Depois vamos plugar os gráficos reais aqui.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.show_chart_rounded,
                  size: 60,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
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
                  onPressed: () {},
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Nova receita'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Nova despesa'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Nova dívida'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions_car_outlined),
                  label: const Text('Financiamento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}