import 'package:flutter/material.dart';

class TransactionFormCard extends StatefulWidget {
  final String selectedType;

  final TextEditingController storeController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final TextEditingController installmentCountController;

  final List<dynamic> expenseCategories;
  final List<dynamic> creditCards;

  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  final String? selectedCreditCardId;
  final ValueChanged<String?> onCreditCardChanged;

  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  final bool markAsPaid;
  final ValueChanged<bool> onMarkAsPaidChanged;

  final bool isInstallment;
  final ValueChanged<bool> onInstallmentChanged;

  final DateTime mainDate;
  final VoidCallback onPickMainDate;

  final DateTime? paidAtDate;
  final VoidCallback onPickPaidAtDate;
  final VoidCallback onClearPaidAt;

  final bool isSaving;
  final VoidCallback onSave;

  final ValueChanged<Set<String>> onTypeChanged;

  const TransactionFormCard({
    super.key,
    required this.selectedType,
    required this.storeController,
    required this.descriptionController,
    required this.amountController,
    required this.installmentCountController,
    required this.expenseCategories,
    required this.creditCards,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.selectedCreditCardId,
    required this.onCreditCardChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.markAsPaid,
    required this.onMarkAsPaidChanged,
    required this.isInstallment,
    required this.onInstallmentChanged,
    required this.mainDate,
    required this.onPickMainDate,
    required this.paidAtDate,
    required this.onPickPaidAtDate,
    required this.onClearPaidAt,
    required this.isSaving,
    required this.onSave,
    required this.onTypeChanged,
  });

  @override
  State<TransactionFormCard> createState() => _TransactionFormCardState();
}

class _TransactionFormCardState extends State<TransactionFormCard> {
  final _scrollController = ScrollController();
  final _cardSectionKey = GlobalKey();

  bool _shouldScrollToCardSection = false;

  @override
  void initState() {
    super.initState();
    widget.amountController.addListener(_refreshPreview);
    widget.installmentCountController.addListener(_refreshPreview);
  }

  @override
  void didUpdateWidget(covariant TransactionFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.amountController != widget.amountController) {
      oldWidget.amountController.removeListener(_refreshPreview);
      widget.amountController.addListener(_refreshPreview);
    }

    if (oldWidget.installmentCountController !=
        widget.installmentCountController) {
      oldWidget.installmentCountController.removeListener(_refreshPreview);
      widget.installmentCountController.addListener(_refreshPreview);
    }

    final turnedIntoCardPurchase =
        oldWidget.selectedCreditCardId == null &&
            widget.selectedCreditCardId != null;

    if (turnedIntoCardPurchase) {
      _shouldScrollToCardSection = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final ctx = _cardSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: 0.15,
          );
        }

        _shouldScrollToCardSection = false;
      });
    }
  }

  @override
  void dispose() {
    widget.amountController.removeListener(_refreshPreview);
    widget.installmentCountController.removeListener(_refreshPreview);
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  double? get _parsedAmount {
    return double.tryParse(
      widget.amountController.text.trim().replaceAll(',', '.'),
    );
  }

  int? get _parsedInstallments {
    return int.tryParse(widget.installmentCountController.text.trim());
  }

  bool get _isExpense => widget.selectedType == 'expense';

  bool get _isCreditCardPurchase => widget.selectedCreditCardId != null;

  double _ceilToCents(double value) {
    return (value * 100).ceil() / 100;
  }

  double? get _installmentAmountPreview {
    final amount = _parsedAmount;
    final installments = _parsedInstallments;

    if (amount == null || amount <= 0) return null;
    if (installments == null || installments < 2) return null;

    return _ceilToCents(amount / installments);
  }

  DateTime get _lastInstallmentDate {
    final installments = _parsedInstallments;
    if (installments == null || installments < 2) {
      return widget.mainDate;
    }

    return DateTime(
      widget.mainDate.year,
      widget.mainDate.month + (installments - 1),
      widget.mainDate.day,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'expense',
                icon: Icon(Icons.arrow_upward),
                label: Text('Despesa'),
              ),
              ButtonSegment<String>(
                value: 'income',
                icon: Icon(Icons.arrow_downward),
                label: Text('Receita'),
              ),
            ],
            selected: {widget.selectedType},
            onSelectionChanged: widget.onTypeChanged,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: widget.descriptionController,
            decoration: InputDecoration(
              labelText: _isExpense ? 'Descrição' : 'Descrição da receita',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: widget.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isExpense ? 'Valor total' : 'Valor recebido',
            ),
          ),
          const SizedBox(height: 16),

          if (_isExpense) ...[
            DropdownButtonFormField<String>(
              value: widget.selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoria',
              ),
              items: widget.expenseCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id as String,
                  child: Text(category.name as String),
                );
              }).toList(),
              onChanged: widget.onCategoryChanged,
            ),
            const SizedBox(height: 16),
          ],

          if (_isExpense) ...[
            Container(
              key: _cardSectionKey,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.credit_card, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Forma de pagamento',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Defina se essa despesa foi feita no cartão ou não.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'wallet',
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        label: Text('Dinheiro / conta'),
                      ),
                      ButtonSegment<String>(
                        value: 'credit',
                        icon: Icon(Icons.credit_card),
                        label: Text('Cartão de crédito'),
                      ),
                    ],
                    selected: {
                      _isCreditCardPurchase ? 'credit' : 'wallet',
                    },
                    onSelectionChanged: (value) {
                      final selection = value.first;

                      if (selection == 'wallet') {
                        widget.onCreditCardChanged(null);
                        if (widget.isInstallment) {
                          widget.onInstallmentChanged(false);
                        }
                        setState(() {
                          widget.storeController.clear();
                          widget.installmentCountController.text = '2';
                        });
                        return;
                      }

                      if (selection == 'credit' &&
                          widget.selectedCreditCardId == null) {
                        setState(() {});
                      }
                    },
                  ),

                  if (_isCreditCardPurchase || widget.creditCards.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: widget.selectedCreditCardId,
                      decoration: const InputDecoration(
                        labelText: 'Cartão de crédito',
                        hintText: 'Selecione o cartão usado na compra',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Não foi no cartão'),
                        ),
                        ...widget.creditCards.map((card) {
                          return DropdownMenuItem<String>(
                            value: card.id as String,
                            child: Text(card.name as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        widget.onCreditCardChanged(value);

                        if (value == null && widget.isInstallment) {
                          widget.onInstallmentChanged(false);
                          widget.storeController.clear();
                          widget.installmentCountController.text = '2';
                        }
                      },
                    ),
                  ],

                  if (_isCreditCardPurchase) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Como essa compra foi lançada no cartão?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'single',
                          icon: Icon(Icons.looks_one_outlined),
                          label: Text('À vista (1x)'),
                        ),
                        ButtonSegment<String>(
                          value: 'installment',
                          icon: Icon(Icons.view_week_outlined),
                          label: Text('Parcelada'),
                        ),
                      ],
                      selected: {
                        widget.isInstallment ? 'installment' : 'single',
                      },
                      onSelectionChanged: (value) {
                        final selection = value.first;

                        if (selection == 'single') {
                          widget.onInstallmentChanged(false);
                          setState(() {
                            widget.storeController.clear();
                            widget.installmentCountController.text = '2';
                          });
                        } else {
                          widget.onInstallmentChanged(true);
                          if (widget.installmentCountController.text.trim().isEmpty ||
                              widget.installmentCountController.text.trim() == '1') {
                            widget.installmentCountController.text = '2';
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isInstallment
                          ? 'Parcelas mensais serão geradas automaticamente.'
                          : 'Essa compra entra na fatura como 1x.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_isExpense && _isCreditCardPurchase && widget.isInstallment) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.lightBlueAccent.withOpacity(0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.receipt_long_outlined, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dados do parcelamento',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados da compra parcelada.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: widget.storeController,
                    autofocus: _shouldScrollToCardSection,
                    decoration: const InputDecoration(
                      labelText: 'Loja',
                      hintText: 'Ex.: Magalu, Airbnb, Mercado Livre',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: widget.installmentCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de parcelas',
                      hintText: 'Ex.: 2, 3, 10, 12',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prévia do parcelamento',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Primeira parcela',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(widget.mainDate),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Última parcela',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_lastInstallmentDate),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Valor estimado de cada parcela',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _installmentAmountPreview != null
                              ? _formatCurrency(_installmentAmountPreview!)
                              : '--',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _isExpense
                  ? widget.isInstallment
                      ? 'Data da primeira parcela'
                      : 'Data de vencimento'
                  : 'Data de recebimento',
            ),
            subtitle: Text(_formatDate(widget.mainDate)),
            trailing: OutlinedButton(
              onPressed: widget.onPickMainDate,
              child: const Text('Escolher data'),
            ),
          ),
          const SizedBox(height: 16),

          if (_isExpense && !widget.isInstallment) ...[
            DropdownButtonFormField<String>(
              value: widget.selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('Pendente'),
                ),
                DropdownMenuItem(
                  value: 'paid',
                  child: Text('Pago'),
                ),
              ],
              onChanged: widget.onStatusChanged,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Marcar como pago'),
              value: widget.markAsPaid,
              onChanged: widget.onMarkAsPaidChanged,
            ),
            const SizedBox(height: 8),
            if (widget.markAsPaid) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do pagamento'),
                subtitle: Text(
                  widget.paidAtDate != null
                      ? _formatDate(widget.paidAtDate!)
                      : 'Não informada',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onPickPaidAtDate,
                      child: const Text('Escolher data'),
                    ),
                    if (widget.paidAtDate != null)
                      OutlinedButton(
                        onPressed: widget.onClearPaidAt,
                        child: const Text('Limpar'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],

          if (!_isExpense) ...[
            const SizedBox(height: 8),
            Text(
              'Receitas são registradas como recebidas na data informada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.isSaving ? null : widget.onSave,
              child: Text(
                widget.isSaving ? 'Salvando...' : 'Salvar transação',
              ),
            ),
          ),
        ],
      ),
    );
  }
}