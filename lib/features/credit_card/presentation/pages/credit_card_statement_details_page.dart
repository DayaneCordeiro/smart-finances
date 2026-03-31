import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transaction/domain/entities/finance_transaction.dart';
import '../../domain/entities/credit_card_adjustment.dart';
import '../controllers/credit_card_statement_rollover_provider.dart';

class CreditCardStatementDetailsPage extends ConsumerStatefulWidget {
  final String userId;
  final String creditCardId;
  final String creditCardName;
  final DateTime initialMonth;

  const CreditCardStatementDetailsPage({
    super.key,
    required this.userId,
    required this.creditCardId,
    required this.creditCardName,
    required this.initialMonth,
  });

  @override
  ConsumerState<CreditCardStatementDetailsPage> createState() =>
      _CreditCardStatementDetailsPageState();
}

class _CreditCardStatementDetailsPageState
    extends ConsumerState<CreditCardStatementDetailsPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statementAsync = ref.watch(
      creditCardStatementMonthProvider(
        CreditCardStatementMonthQuery(
          userId: widget.userId,
          creditCardId: widget.creditCardId,
          month: _selectedMonth,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura • ${widget.creditCardName}'),
      ),
      body: statementAsync.when(
        data: (statement) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _monthLabel(_selectedMonth),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 700;

                        final summaryChildren = [
                          _SummaryItem(
                            title: 'Compras do mês',
                            value: _formatCurrency(statement.purchasesTotal),
                          ),
                          _SummaryItem(
                            title: 'Estornos/créditos do mês',
                            value: _formatCurrency(-statement.monthAdjustmentsTotal),
                          ),
                          _SummaryItem(
                            title: 'Crédito aplicado',
                            value: _formatCurrency(-statement.appliedCredit),
                          ),
                          _SummaryItem(
                            title: 'Total da fatura',
                            value: _formatCurrency(statement.finalTotal),
                            highlight: true,
                          ),
                        ];

                        if (statement.carryOverCredit > 0) {
                          summaryChildren.add(
                            _SummaryItem(
                              title: 'Crédito para o próximo mês',
                              value: _formatCurrency(statement.carryOverCredit),
                            ),
                          );
                        }

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...summaryChildren.expand((item) => [
                                    item,
                                    const SizedBox(height: 14),
                                  ]),
                            ],
                          );
                        }

                        return Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: summaryChildren
                              .map(
                                (item) => SizedBox(
                                  width: 220,
                                  child: item,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Compras do mês',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Todas as compras vinculadas a este cartão no mês selecionado.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),
                if (statement.monthTransactions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhuma compra encontrada neste mês.'),
                    ),
                  )
                else
                  ...statement.monthTransactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StatementTransactionCard(
                        transaction: transaction,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Estornos e créditos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créditos aplicados neste cartão no mês selecionado.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),
                if (statement.monthAdjustments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhum estorno/crédito neste mês.'),
                    ),
                  )
                else
                  ...statement.monthAdjustments.map(
                    (adjustment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdjustmentCard(
                        adjustment: adjustment,
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
          child: Text('Erro ao carregar fatura: $error'),
        ),
      ),
    );
  }

  String _monthLabel(DateTime date) {
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

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return isNegative ? '-R\$ $formatted' : 'R\$ $formatted';
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _SummaryItem({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = highlight
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.titleLarge?.copyWith(
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
        const SizedBox(height: 8),
        Text(
          value,
          style: valueStyle,
        ),
      ],
    );
  }
}

class _StatementTransactionCard extends StatelessWidget {
  final FinanceTransaction transaction;

  const _StatementTransactionCard({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final store = (transaction.storeName ?? '').trim();
    final description = transaction.description.trim();
    final showSubtitle =
        store.isNotEmpty && store.toLowerCase() != description.toLowerCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.08),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      store,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    _statusLabel(transaction.status),
                    style: TextStyle(
                      color: _statusColor(transaction.status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(transaction.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                if (transaction.installmentNumber != null &&
                    transaction.installmentTotal != null)
                  Text(
                    '${transaction.installmentNumber}/${transaction.installmentTotal}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                if (transaction.dueDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(transaction.dueDate!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Pago';
      case 'received':
        return 'Recebido';
      case 'overdue':
        return 'Atrasado';
      default:
        return 'Pendente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'received':
        return Colors.greenAccent;
      case 'overdue':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }
}

class _AdjustmentCard extends StatelessWidget {
  final CreditCardAdjustment adjustment;

  const _AdjustmentCard({
    required this.adjustment,
  });

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return isNegative ? '-R\$ $formatted' : 'R\$ $formatted';
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String get _label {
    switch (adjustment.type) {
      case 'refund':
        return 'Estorno';
      default:
        return 'Crédito aplicado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRefund = adjustment.type == 'refund';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.lightBlueAccent.withOpacity(0.14),
              child: Icon(
                isRefund ? Icons.undo : Icons.account_balance_wallet_outlined,
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(adjustment.adjustmentDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatCurrency(-adjustment.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.lightBlueAccent,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}