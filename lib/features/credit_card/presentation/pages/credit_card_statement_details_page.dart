import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transaction/domain/entities/finance_transaction.dart';
import '../../../transaction/presentation/controllers/transaction_providers.dart';

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
    final transactionsAsync = ref.watch(transactionsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura • ${widget.creditCardName}'),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final monthTransactions = _filterTransactions(transactions);

          final totalAmount = monthTransactions.fold<double>(
            0,
            (sum, item) => sum + item.amount,
          );

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

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SummaryItem(
                                title: 'Cartão',
                                value: widget.creditCardName,
                              ),
                              const SizedBox(height: 14),
                              _SummaryItem(
                                title: 'Lançamentos',
                                value: '${monthTransactions.length}',
                              ),
                              const SizedBox(height: 14),
                              _SummaryItem(
                                title: 'Total da fatura',
                                value: _formatCurrency(totalAmount),
                                highlight: true,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _SummaryItem(
                                title: 'Cartão',
                                value: widget.creditCardName,
                              ),
                            ),
                            Expanded(
                              child: _SummaryItem(
                                title: 'Lançamentos',
                                value: '${monthTransactions.length}',
                              ),
                            ),
                            Expanded(
                              child: _SummaryItem(
                                title: 'Total da fatura',
                                value: _formatCurrency(totalAmount),
                                highlight: true,
                              ),
                            ),
                          ],
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
                if (monthTransactions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhuma compra encontrada neste mês.'),
                    ),
                  )
                else
                  ...monthTransactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StatementTransactionCard(
                        transaction: transaction,
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

  List<FinanceTransaction> _filterTransactions(
    List<FinanceTransaction> transactions,
  ) {
    final filtered = transactions.where((transaction) {
      if (transaction.type != 'expense') return false;
      if (transaction.creditCardId != widget.creditCardId) return false;
      if (transaction.dueDate == null) return false;

      final dueDate = transaction.dueDate!;
      return dueDate.year == _selectedMonth.year &&
          dueDate.month == _selectedMonth.month;
    }).toList();

    filtered.sort((a, b) {
      final aDate = a.dueDate ?? DateTime(2100);
      final bDate = b.dueDate ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });

    return filtered;
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
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
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