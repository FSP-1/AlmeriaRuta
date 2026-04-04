import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../viewmodels/notifications_viewmodel.dart';

class ArrivalSettingsCard extends StatelessWidget {
  final NotificationsViewModel vm;
  final Future<void> Function() onPickStop;

  const ArrivalSettingsCard({
    super.key,
    required this.vm,
    required this.onPickStop,
  });

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Aviso de llegada'),
            subtitle: const Text('Cuando falten X minutos para llegar a una parada'),
            value: draft.arrival.enabled,
            onChanged: vm.setArrivalEnabled,
          ),
          ListTile(
            title: const Text('Avisar con antelacion'),
            subtitle: Text('${draft.arrival.leadMinutes} minutos'),
            enabled: draft.arrival.enabled,
            trailing: DropdownButton<int>(
              value: draft.arrival.leadMinutes,
              onChanged: !draft.arrival.enabled
                  ? null
                  : (v) {
                      if (v != null) vm.setArrivalLeadMinutes(v);
                    },
              items: const [1, 3, 5, 10, 15]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                  .toList(),
            ),
          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Parada'),
            subtitle: Text(_formatArrivalStopSubtitle(draft.arrival.stopName, draft.arrival.lineName) ?? 'Sin seleccionar'),
            enabled: draft.arrival.enabled,
            trailing: const Icon(Icons.location_on, color: AppTheme.lightRed),
            onTap: !draft.arrival.enabled ? null : onPickStop,
          ),
          if (draft.arrival.enabled)
            TextButton(
              onPressed: vm.clearArrivalTarget,
              child: const Text('Limpiar seleccion'),
            ),
        ],
      ),
    );
  }

  String? _formatArrivalStopSubtitle(String? stopName, String? lineName) {
    if (stopName == null || stopName.isEmpty) return null;
    if (lineName == null || lineName.isEmpty) return stopName;
    return '$stopName · Linea: $lineName';
  }
}
