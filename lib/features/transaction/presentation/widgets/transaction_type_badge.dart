import 'package:flutter/material.dart';

class TransactionTypeBadge extends StatelessWidget {
  final String type;

  const TransactionTypeBadge({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'income';

    final backgroundColor = isIncome
        ? Colors.green.withOpacity(0.16)
        : Colors.orange.withOpacity(0.16);

    final borderColor = isIncome
        ? Colors.green.withOpacity(0.35)
        : Colors.orange.withOpacity(0.35);

    final textColor = isIncome ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        isIncome ? 'Entrada' : 'Saída',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}