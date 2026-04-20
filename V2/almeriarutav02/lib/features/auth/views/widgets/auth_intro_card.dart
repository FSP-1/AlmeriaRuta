import 'package:flutter/material.dart';

class AuthIntroCard extends StatelessWidget {
  const AuthIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acceso con reglas claras',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Registrarte activa el uso de tarjeta bus, tarjeta saldo y la compra de tickets para otros usuarios.',
              style: TextStyle(
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
