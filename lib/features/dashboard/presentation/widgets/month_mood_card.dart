import 'package:flutter/material.dart';

enum MonthMood {
  happy,
  ok,
  warning,
  sad,
}

class MonthMoodCard extends StatelessWidget {
  final double balance;

  const MonthMoodCard({
    super.key,
    required this.balance,
  });

  MonthMood get mood {
    if (balance >= 100) return MonthMood.happy;
    if (balance >= 50) return MonthMood.ok;
    if (balance >= -200) return MonthMood.warning;
    return MonthMood.sad;
  }

  String get title {
    switch (mood) {
      case MonthMood.happy:
        return 'Seu mês está indo super bem 🐶';
      case MonthMood.ok:
        return 'Seu mês está sob controle 🐶';
      case MonthMood.warning:
        return 'Opa, melhor ficar de olho 🐶';
      case MonthMood.sad:
        return 'O cachorrinho ficou triste 🐶';
    }
  }

  String get description {
    switch (mood) {
      case MonthMood.happy:
        return 'Saldo bem positivo. Você está conseguindo manter uma boa folga no mês.';
      case MonthMood.ok:
        return 'Saldo positivo, mas sem muita sobra. Vale acompanhar os próximos gastos.';
      case MonthMood.warning:
        return 'Saldo baixo ou levemente negativo. Talvez seja hora de revisar despesas e parcelas.';
      case MonthMood.sad:
        return 'Saldo bem negativo no momento. O ideal é revisar gastos, dívidas e vencimentos.';
    }
  }

  String get assetPath {
    switch (mood) {
      case MonthMood.happy:
        return 'assets/images/dog_happy.png';
      case MonthMood.ok:
        return 'assets/images/dog_ok.png';
      case MonthMood.warning:
        return 'assets/images/dog_warning.png';
      case MonthMood.sad:
        return 'assets/images/dog_sad.png';
    }
  }

  Color get badgeColor {
    switch (mood) {
      case MonthMood.happy:
        return const Color(0xFF22C55E);
      case MonthMood.ok:
        return const Color(0xFF60A5FA);
      case MonthMood.warning:
        return const Color(0xFFF59E0B);
      case MonthMood.sad:
        return const Color(0xFFEF4444);
    }
  }

  String get badgeText {
    switch (mood) {
      case MonthMood.happy:
        return 'Muito positivo';
      case MonthMood.ok:
        return 'Estável';
      case MonthMood.warning:
        return 'Atenção';
      case MonthMood.sad:
        return 'Crítico';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 130,
              height: 130,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.pets,
                      size: 56,
                      color: Colors.white54,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Saldo atual: ${_formatCurrency(balance)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final absValue = value.abs().toStringAsFixed(2).replaceAll('.', ',');

    return isNegative ? '-R\$ $absValue' : 'R\$ $absValue';
  }
}