import 'package:flutter/material.dart';

class RechargeErrorBanner extends StatelessWidget {
  final String error;

  const RechargeErrorBanner({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        error,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
