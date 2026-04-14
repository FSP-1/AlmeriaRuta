import 'package:flutter/material.dart';

class AdditionalCardHint extends StatelessWidget {
  const AdditionalCardHint({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Activa una tarjeta adicional desde el menú superior derecho.',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
