import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'As categorias agora são automáticas do sistema.\n\n'
                'Disponíveis:\n'
                '• Despesa fixa\n'
                '• Despesa variável\n'
                '• Despesa extra\n'
                '• Financiamento',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}