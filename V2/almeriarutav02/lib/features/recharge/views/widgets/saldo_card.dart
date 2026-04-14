import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/transport_card_model.dart';

class SaldoCard extends StatelessWidget {
  final TransportCardModel card;
  final bool isExpired;
  final VoidCallback onAddSaldo;

  const SaldoCard({
    super.key,
    required this.card,
    required this.isExpired,
    required this.onAddSaldo,
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
                  Icons.account_balance_wallet,
                  color: isExpired ? Colors.grey : AppTheme.primaryRed,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tarjeta Saldo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Saldo actual: ${card.balance.toStringAsFixed(2)} EUR'),
            const SizedBox(height: 4),
            const Text(
              'Recarga libre para añadir saldo a tu tarjeta.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: onAddSaldo,
                child: const Text('Añadir saldo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
