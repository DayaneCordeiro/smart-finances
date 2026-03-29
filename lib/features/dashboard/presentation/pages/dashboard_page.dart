import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/pages/category_page.dart';
import '../../../credit_card/presentation/pages/credit_card_statement_details_page.dart';
import '../../../credit_card/presentation/pages/credit_cards_page.dart';
import '../../../credit_card/presentation/widgets/credit_card_statement_card.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';
import '../../../transaction/presentation/pages/transaction_page.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../../user/presentation/pages/user_list_page.dart';
import '../../domain/entities/monthly_summary.dart';
import '../controllers/dashboard_providers.dart';
import '../widgets/month_mood_card.dart';
import '../../../financing/presentation/pages/financing_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserAsync = ref.watch(activeUserProvider);
    final summaryAsync = ref.watch(dashboardActiveUserSummaryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
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
                      if (activeUser == null) {
                        return const Center(
                          child: Text('Nenhum usuário ativo'),
                        );
                      }

                      final creditCardStatementsAsync =
                          ref.watch(creditCardStatementsProvider(activeUser.id));

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
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CreditCardsPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.credit_card),
                                      label: const Text('Cartões'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const TransactionPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Nova transação'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _MonthSelector(
                              selectedMonth: selectedMonth,
                            ),
                            const SizedBox(height: 20),
                            _MonthHighlightCard(
                              balance: summary?.balance ?? 0,
                              selectedMonth: selectedMonth,
                            ),
                            const SizedBox(height: 20),
                            MonthMoodCard(
                              balance: summary?.balance ?? 0,
                              overdueCount: summary?.overdueCount ?? 0,
                            ),
                            const SizedBox(height: 20),
                            _SummaryCardsSection(summary: summary),
                            const SizedBox(height: 20),
                            _CreditCardStatementsSection(
                              asyncValue: creditCardStatementsAsync,
                              onPayBill: (statement) async {
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  initialDate: DateTime.now(),
                                );

                                if (picked == null) return;

                                await ref
                                    .read(transactionControllerProvider)
                                    .payCreditCardBill(
                                      userId: activeUser.id,
                                      creditCardId: statement.card.id,
                                      monthReference:
                                          statement.referenceMonth,
                                      paidAt: picked,
                                    );

                                ref.invalidate(
                                  filteredTransactionsByMonthProvider(
                                    activeUser.id,
                                  ),
                                );
                                ref.invalidate(
                                  monthlySummaryProvider(activeUser.id),
                                );
                                ref.invalidate(
                                  dashboardActiveUserSummaryProvider,
                                );
                                ref.invalidate(
                                  creditCardStatementsProvider(activeUser.id),
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Fatura ${statement.card.name} marcada como paga',
                                      ),
                                    ),
                                  );
                                }
                              },
                              onOpenDetails: (statement) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreditCardStatementDetailsPage(
                                      userId: activeUser.id,
                                      creditCardId: statement.card.id,
                                      creditCardName: statement.card.name,
                                      initialMonth: statement.referenceMonth,
                                    ),
                                  ),
                                );
                              },
                            ),
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

class _MonthSelector extends ConsumerWidget {
  final DateTime selectedMonth;

  const _MonthSelector({
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(selectedMonth.year, selectedMonth.month - 1);
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthLabel(selectedMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(selectedMonth.year, selectedMonth.month + 1);
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
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
          _SidebarItem(
            icon: Icons.credit_card_outlined,
            title: 'Cartões',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreditCardsPage()),
              );
            },
          ),
          const _SidebarItem(
            icon: Icons.receipt_long_outlined,
            title: 'Dívidas',
          ),
          _SidebarItem(
            icon: Icons.directions_car_outlined,
            title: 'Financiamento',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FinancingPage(),
                ),
              );
            },
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
  final DateTime selectedMonth;

  const _MonthHighlightCard({
    required this.balance,
    required this.selectedMonth,
  });

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
                _monthLabel(selectedMonth),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seu saldo atual considera apenas o que já foi pago ou recebido.',
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
  final MonthlySummary? summary;

  const _SummaryCardsSection({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Entradas',
                value: _formatCurrency(summary?.totalIncome ?? 0),
                subtitle: 'Receitas recebidas no mês',
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Saídas',
                value: _formatCurrency(summary?.totalExpense ?? 0),
                subtitle: 'Despesas pagas no mês',
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pendentes',
                value: _formatCurrency(summary?.pendingTotal ?? 0),
                subtitle: 'Itens pendentes ou atrasados',
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Atrasados',
                value: '${summary?.overdueCount ?? 0}',
                subtitle: 'Lançamentos vencidos',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 165),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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

class _CreditCardStatementsSection extends StatelessWidget {
  final AsyncValue<List<CreditCardStatementView>> asyncValue;
  final Future<void> Function(CreditCardStatementView statement) onPayBill;
  final void Function(CreditCardStatementView statement) onOpenDetails;

  const _CreditCardStatementsSection({
    required this.asyncValue,
    required this.onPayBill,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (statements) {
        if (statements.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faturas do cartão',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe e quite as faturas vinculadas ao mês selecionado.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (statements.length == 1) {
                      final statement = statements.first;

                      return SizedBox(
                        width: double.infinity,
                        child: CreditCardStatementCard(
                          cardName: statement.card.name,
                          amount: statement.totalAmount,
                          itemsCount: statement.itemsCount,
                          isPaid: statement.isPaid,
                          paidAt: statement.paidAt,
                          onPayBill: statement.isPaid
                              ? null
                              : () => onPayBill(statement),
                          onOpenDetails: () => onOpenDetails(statement),
                        ),
                      );
                    }

                    final maxWidth = constraints.maxWidth;
                    int crossAxisCount = 2;

                    if (maxWidth >= 1400) {
                      crossAxisCount = 3;
                    } else if (maxWidth < 700) {
                      crossAxisCount = 1;
                    }

                    final spacing = 16.0;
                    final itemWidth =
                        (maxWidth - (spacing * (crossAxisCount - 1))) /
                            crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: statements.map((statement) {
                        return SizedBox(
                          width: itemWidth,
                          child: CreditCardStatementCard(
                            cardName: statement.card.name,
                            amount: statement.totalAmount,
                            itemsCount: statement.itemsCount,
                            isPaid: statement.isPaid,
                            paidAt: statement.paidAt,
                            onPayBill: statement.isPaid
                                ? null
                                : () => onPayBill(statement),
                            onOpenDetails: () => onOpenDetails(statement),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => Text(
        'Erro ao carregar faturas: $error',
      ),
    );
  }
}

class _ChartsAndAlertsSection extends StatelessWidget {
  final MonthlySummary? summary;

  const _ChartsAndAlertsSection({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        if (isCompact) {
          return Column(
            children: [
              _FinancialOverviewCard(summary: summary),
              const SizedBox(height: 16),
              _AlertCard(
                title: 'Itens atrasados',
                description: (summary?.overdueCount ?? 0) > 0
                    ? 'Você tem ${summary!.overdueCount} item(ns) atrasado(s) neste mês.'
                    : 'Nenhum item atrasado neste mês.',
                icon: Icons.alarm,
              ),
              const SizedBox(height: 16),
              _AlertCard(
                title: 'Situação do saldo',
                description: (summary?.balance ?? 0) >= 0
                    ? 'Seu saldo atual está positivo.'
                    : 'Seu saldo atual está negativo.',
                icon: Icons.pie_chart_outline,
              ),
            ],
          );
        }

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
                    description: (summary?.overdueCount ?? 0) > 0
                        ? 'Você tem ${summary!.overdueCount} item(ns) atrasado(s) neste mês.'
                        : 'Nenhum item atrasado neste mês.',
                    icon: Icons.alarm,
                  ),
                  const SizedBox(height: 16),
                  _AlertCard(
                    title: 'Situação do saldo',
                    description: (summary?.balance ?? 0) >= 0
                        ? 'Seu saldo atual está positivo.'
                        : 'Seu saldo atual está negativo.',
                    icon: Icons.pie_chart_outline,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FinancialOverviewCard extends StatelessWidget {
  final MonthlySummary? summary;

  const _FinancialOverviewCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncome = summary?.totalIncome ?? 0.0;
    final totalExpense = summary?.totalExpense ?? 0.0;
    final balance = summary?.balance ?? 0.0;
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
              'Valores realizados e pendentes do mês selecionado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            _InfoRow(
              label: 'Receitas recebidas',
              value: _formatCurrency(totalIncome),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Despesas pagas',
              value: _formatCurrency(totalExpense),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Pendentes/atrasados',
              value: _formatCurrency(pending),
            ),
            const Divider(height: 32),
            _InfoRow(
              label: 'Saldo atual',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: style),
              const SizedBox(height: 6),
              Text(
                value,
                style: style,
                textAlign: TextAlign.left,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: style),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                style: style,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
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