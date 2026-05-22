import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/operario_viewmodel.dart';
import '../../../map/viewmodels/notices_viewmodel.dart';
import 'operario_view_utils.dart';

class OperarioStopsTab extends StatelessWidget {
  const OperarioStopsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OperarioViewModel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          vm.successMessage!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (vm.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          vm.error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Buscar parada por nombre o posición',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: vm.setDisableStopSearchQuery,
                enabled: !vm.loading,
                decoration: InputDecoration(
                  hintText: 'Ej: Rambla, S123, 36.83821,-2.46210',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  itemCount: vm.filteredStopsForDisableSearch.length,
                  itemBuilder: (context, i) {
                    final stop = vm.filteredStopsForDisableSearch[i];
                    final selected = vm.selectedStopForDisable?.id == stop.id;
                    final alreadyDisabled = vm.disabledStops.any((s) => s.stopId == stop.id);

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? const Color(0xFFF59E0B) : Colors.grey,
                      ),
                      title: Text(
                        stop.name,
                        style: alreadyDisabled
                            ? TextStyle(color: Colors.grey.shade600)
                            : null,
                      ),
                      subtitle: Text(
                        'ID: ${stop.id} · ${stop.lat.toStringAsFixed(5)}, ${stop.lon.toStringAsFixed(5)}',
                        style: alreadyDisabled
                            ? TextStyle(color: Colors.grey.shade600)
                            : null,
                      ),
                      onTap: vm.loading ? null : () => vm.selectStopForDisable(stop),
                      trailing: alreadyDisabled
                          ? Icon(Icons.block, size: 18, color: Colors.grey.shade600)
                          : null,
                    );
                  },
                ),
              ),
              if (vm.selectedStopForDisable != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleccionada: ${vm.selectedStopForDisable!.name} (${vm.selectedStopForDisable!.id})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: vm.loading ? null : vm.clearDisableStopSelection,
                      child: const Text('Quitar'),
                    ),
                  ],
                ),
              ],
              if (vm.error == 'Selecciona una parada con el buscador')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    vm.error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Razón de deshabilitación',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                onChanged: vm.setStopReason,
                enabled: !vm.loading,
                decoration: InputDecoration(
                  hintText: 'Ej: Obras en la acera',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (vm.error == 'La razón es requerida')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    vm.error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (vm.loading || vm.isSelectedStopAlreadyDisabled)
                      ? null
                      : () async {
                          final ok = await vm.disableStop();
                          if (!context.mounted) return;
                          if (!ok) {
                            final msg = vm.error ?? 'Error al deshabilitar parada';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          } else {
                            await context.read<NoticesViewModel>().loadNotices();
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Parada deshabilitada')));
                          }
                        },
                  icon: vm.loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.block),
                  label: Text(
                    vm.loading
                        ? 'Deshabilitando...'
                        : (vm.isSelectedStopAlreadyDisabled ? 'Ya está deshabilitada' : 'Deshabilitar Parada'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (vm.disabledStops.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Paradas deshabilitadas',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...vm.disabledStops.map((stop) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.stopName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${stop.stopId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: vm.loading
                                    ? null
                                    : () async {
                                        await vm.enableStop(stop.stopId);
                                        if (!context.mounted) return;
                                        await context.read<NoticesViewModel>().loadNotices();
                                        if (vm.error != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(content: Text(vm.error!)));
                                        } else if (vm.successMessage != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(content: Text(vm.successMessage!)));
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Habilitar',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Razón: ${stop.reason}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Desde: ${operarioFormatDate(stop.disabledAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
