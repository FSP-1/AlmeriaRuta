import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../viewmodels/notifications_viewmodel.dart';

class RechargeSettingsCard extends StatelessWidget {
  final NotificationsViewModel vm;

  const RechargeSettingsCard({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Recordatorio de mensual'),
            subtitle: const Text('Aviso 3 dias antes de caducar'),
            value: draft.recharge.enabled,
            onChanged: vm.setRechargeEnabled,
          ),
          ListTile(
            title: const Text('Fecha de caducidad'),
            subtitle: Text(_formatIsoDate(draft.recharge.monthlyExpiryDateIso) ?? 'Sin seleccionar'),
            trailing: const Icon(Icons.event, color: AppTheme.lightRed),
            enabled: draft.recharge.enabled,
            onTap: !draft.recharge.enabled
                ? null
                : () async {
                    final initial = _tryParseIsoDate(draft.recharge.monthlyExpiryDateIso) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (!context.mounted) return;
                    vm.setMonthlyExpiryDate(picked);
                  },
          ),
          ListTile(
            title: const Text('Hora del aviso'),
            subtitle: Text(_formatTime(draft.recharge.hour, draft.recharge.minute)),
            trailing: const Icon(Icons.schedule, color: AppTheme.lightRed),
            enabled: draft.recharge.enabled,
            onTap: !draft.recharge.enabled
                ? null
                : () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: draft.recharge.hour,
                        minute: draft.recharge.minute,
                      ),
                    );
                    if (!context.mounted) return;
                    if (time != null) {
                      vm.setRechargeTime(time);
                    }
                  },
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? _formatIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return iso;
  }

  DateTime? _tryParseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parts = iso.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
