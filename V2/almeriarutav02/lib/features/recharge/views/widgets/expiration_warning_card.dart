import 'package:flutter/material.dart';

import '../../models/transport_card_model.dart';

class ExpirationWarningCard extends StatelessWidget {
  final TransportCardModel card;
  final String formattedExpiration;

  const ExpirationWarningCard({
    super.key,
    required this.card,
    required this.formattedExpiration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Tarjeta próxima a caducar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${card.name}: $formattedExpiration',
            style: TextStyle(color: Colors.orange[800]),
          ),
        ],
      ),
    );
  }
}
