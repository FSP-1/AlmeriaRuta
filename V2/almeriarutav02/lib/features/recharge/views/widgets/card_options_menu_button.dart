import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recharge_profile_model.dart';

class CardOptionsMenuButton extends StatelessWidget {
  final List<RechargeCardOption> options;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const CardOptionsMenuButton({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune),
      tooltip: 'Tarjetas activas',
      onSelected: onSelected,
      itemBuilder: (context) {
        return options
            .where((option) => option.key != 'saldo_virtual')
            .map((option) {
          final selected = selectedKey == option.key;
          return PopupMenuItem<String>(
            value: option.key,
            child: Row(
              children: [
                Expanded(child: Text(option.title)),
                if (selected) const Icon(Icons.check, color: AppTheme.primaryRed),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
