import 'package:flutter/material.dart';

class FirstRechargeHint extends StatelessWidget {
  const FirstRechargeHint({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'Primera recarga: introduce el importe que quieres añadir.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
