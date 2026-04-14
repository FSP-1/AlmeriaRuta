import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/transport_card_model.dart';

class TransportCard extends StatelessWidget {
  final TransportCardModel card;
  final bool isExpired;
  final bool canRecharge;
  final double amount;
  final String expirationText;
  final VoidCallback? onRenew;

  const TransportCard({
    super.key,
    required this.card,
    required this.isExpired,
    required this.canRecharge,
    required this.amount,
    required this.expirationText,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isExpired ? Colors.grey[300] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: isExpired ? Colors.grey : AppTheme.primaryRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Importe fijo: ${amount.toStringAsFixed(2)} EUR'),
            const SizedBox(height: 4),
            Text(
              expirationText,
              style: TextStyle(color: isExpired ? Colors.red : Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              card.type == CardType.monthly
                  ? 'Recarga mensual activa.'
                  : 'Recarga por usos o bonificación aplicada.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRecharge ? AppTheme.primaryRed : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: canRecharge ? onRenew : null,
                child: const Text('Renovar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
