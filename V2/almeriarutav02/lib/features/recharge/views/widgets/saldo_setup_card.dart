import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SaldoSetupCard extends StatelessWidget {
  final VoidCallback onCreate;

  const SaldoSetupCard({
    super.key,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarjeta saldo no creada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Crea tu tarjeta saldo para poder recargar y pagar billetes con saldo.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: onCreate,
                child: const Text('Crear tarjeta saldo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
