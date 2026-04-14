import 'package:flutter/material.dart';

class RechargeLoadingIndicator extends StatelessWidget {
  const RechargeLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: LinearProgressIndicator(minHeight: 2),
    );
  }
}
