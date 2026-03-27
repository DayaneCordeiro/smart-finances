import 'package:flutter/material.dart';

import '../../domain/entities/credit_card_entity.dart';

class EditCreditCardPage extends StatefulWidget {
  final CreditCardEntity card;

  const EditCreditCardPage({
    super.key,
    required this.card,
  });

  @override
  State<EditCreditCardPage> createState() => _EditCreditCardPageState();
}

class _EditCreditCardPageState extends State<EditCreditCardPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _closingDayController;
  late final TextEditingController _dueDayController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card.name);
    _closingDayController =
        TextEditingController(text: widget.card.closingDay.toString());
    _dueDayController =
        TextEditingController(text: widget.card.dueDay.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final closingDay = int.tryParse(_closingDayController.text.trim());
    final dueDay = int.tryParse(_dueDayController.text.trim());

    if (name.isEmpty) {
      _showError('Informe o nome do cartão');
      return;
    }

    if (closingDay == null || closingDay < 1 || closingDay > 31) {
      _showError('Informe um dia de fechamento válido');
      return;
    }

    if (dueDay == null || dueDay < 1 || dueDay > 31) {
      _showError('Informe um dia de vencimento válido');
      return;
    }

    Navigator.of(context).pop(
      EditCreditCardResult(
        name: name,
        closingDay: closingDay,
        dueDay: dueDay,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar cartão'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cartão',
                    hintText: 'Ex.: Nubank',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _closingDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dia de fechamento',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dueDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dia de vencimento',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar alterações'),
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

class EditCreditCardResult {
  final String name;
  final int closingDay;
  final int dueDay;

  const EditCreditCardResult({
    required this.name,
    required this.closingDay,
    required this.dueDay,
  });
}