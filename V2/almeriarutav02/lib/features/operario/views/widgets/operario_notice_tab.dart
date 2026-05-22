import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/operario_viewmodel.dart';
import 'operario_notice_card.dart';
import 'operario_view_utils.dart';

class OperarioNoticeTab extends StatefulWidget {
  const OperarioNoticeTab({super.key});

  @override
  State<OperarioNoticeTab> createState() => _OperarioNoticeTabState();
}

class _OperarioNoticeTabState extends State<OperarioNoticeTab> {
  bool _lineStopsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<OperarioViewModel>(
      builder: (context, vm, _) {
        final sortedNotices = vm.sortedNotices;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear aviso',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Orden de visualización en app: GENERAL -> TURISMO -> LINEA -> PARADA',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
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
                'Título del aviso',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLength: 100,
                onChanged: vm.setNoticeTitle,
                enabled: !vm.loading,
                decoration: InputDecoration(
                  hintText: 'Ej: Cambio en línea L1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterText: '${vm.noticeTitle.length}/100',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mensaje',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLength: 500,
                maxLines: 4,
                onChanged: vm.setNoticeMessage,
                enabled: !vm.loading,
                decoration: InputDecoration(
                  hintText: 'Describe el cambio o novedad...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterText: '${vm.noticeMessage.length}/500',
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    vm.error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Tipo de aviso',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: vm.noticeType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onChanged: vm.loading
                      ? null
                      : (value) {
                          if (value != null) vm.setNoticeType(value);
                        },
                  items: vm.noticeTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  operarioTypeIcon(type),
                                  size: 18,
                                  color: operarioTypeColor(type),
                                ),
                                const SizedBox(width: 8),
                                Text(type),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (vm.noticeType == 'LINEA') ...[
                const Text(
                  'Línea afectada',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: vm.selectedLineId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    hint: const Text('Selecciona una línea'),
                    onChanged: vm.loading ? null : (v) => vm.selectLine(v),
                    items: vm.lines
                        .map(
                          (line) => DropdownMenuItem<String>(
                            value: line.id,
                            child: Text('${line.name} · ${line.fullName}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (vm.lineStops.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Paradas de la línea (marca las afectadas)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              icon: Icon(_lineStopsExpanded ? Icons.expand_less : Icons.expand_more),
                              onPressed: () => setState(() => _lineStopsExpanded = !_lineStopsExpanded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!_lineStopsExpanded) ...[
                          Text('${vm.lineStops.length} paradas (ocultas)'),
                          if (vm.selectedLineStopIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: vm.lineStops
                                    .where((s) => vm.selectedLineStopIds.contains(s.id))
                                    .map((s) => Chip(label: Text(s.name)))
                                    .toList(),
                              ),
                            ),
                        ] else ...[
                          SizedBox(
                            height: 220,
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                ...vm.lineStops.map(
                                  (stop) => SwitchListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: const Color(0xFFDC2626),
                                    title: Text(stop.name),
                                    subtitle: Text('ID: ${stop.id}'),
                                    value: vm.selectedLineStopIds.contains(stop.id),
                                    onChanged: vm.loading
                                        ? null
                                        : (selected) => vm.toggleLineStop(stop.id, selected),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ] else if (vm.noticeType == 'PARADA') ...[
                const Text(
                  'Buscar parada por nombre o posición',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: vm.setStopSearchQuery,
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
                    itemCount: vm.filteredStopsForSearch.length,
                    itemBuilder: (context, i) {
                      final stop = vm.filteredStopsForSearch[i];
                      final selected = vm.selectedStopForNotice?.id == stop.id;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? const Color(0xFFF59E0B) : Colors.grey,
                        ),
                        title: Text(stop.name),
                        subtitle: Text(
                          'ID: ${stop.id} · ${stop.lat.toStringAsFixed(5)}, ${stop.lon.toStringAsFixed(5)}',
                        ),
                        onTap: vm.loading ? null : () => vm.selectStopForNotice(stop),
                      );
                    },
                  ),
                ),
              ] else ...[
                const Text(
                  'ID relacionado (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => vm.setNoticeRelatedId(value.isEmpty ? null : value),
                  enabled: !vm.loading,
                  decoration: InputDecoration(
                    hintText: 'Ej: ID de línea o parada afectada',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          final ok = await vm.createNotice();
                          if (!context.mounted) return;
                          if (!ok) {
                            final msg = vm.error ?? 'Error al crear aviso';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aviso creado')));
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
                      : const Icon(Icons.send),
                  label: Text(
                    vm.loading ? 'Creando...' : 'Crear Aviso',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: operarioTypeColor(vm.noticeType),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Avisos activos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (sortedNotices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('No hay avisos activos.'),
                )
              else
                ...sortedNotices.map((notice) => OperarioNoticeCard(vm: vm, notice: notice)),
            ],
          ),
        );
      },
    );
  }
}
