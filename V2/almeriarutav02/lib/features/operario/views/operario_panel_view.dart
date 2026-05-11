import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/operario_viewmodel.dart';
import '../../../shared/services/line_models.dart';

class OperarioPanelView extends StatefulWidget {
  const OperarioPanelView({super.key});

  @override
  State<OperarioPanelView> createState() => _OperarioPanelViewState();
}

class _OperarioPanelViewState extends State<OperarioPanelView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _lineStopsExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperarioViewModel>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Operario'),
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign_outlined),
              text: 'Avisos',
            ),
            Tab(
              icon: Icon(Icons.bus_alert),
              text: 'Paradas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNoticeTab(context),
          _buildStopsTab(context),
        ],
      ),
    );
  }

  Widget _buildNoticeTab(BuildContext context) {
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

              // Success message
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

              // Error message
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

              // Title field
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

              // Message field
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

              // Type dropdown
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
                                  _typeIcon(type),
                                  size: 18,
                                  color: _typeColor(type),
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

              // Create button
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
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    vm.loading ? 'Creando...' : 'Crear Aviso',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor(vm.noticeType),
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
                ...sortedNotices.map((notice) => _buildNoticeCard(vm, notice)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopsTab(BuildContext context) {
    return Consumer<OperarioViewModel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success message
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

              // Error message
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

              // Stop ID field
              const Text(
                'ID de la parada',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: vm.setStopId,
                enabled: !vm.loading,
                decoration: InputDecoration(
                  hintText: 'Ej: S123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (vm.error == 'El ID de la parada es requerido')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    vm.error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),

              // Stop name field
              const Text(
                'Nombre de la parada',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: vm.setStopName,
                enabled: !vm.loading,
                decoration: InputDecoration(
                  hintText: 'Ej: Plaza Mayor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (vm.error == 'El nombre de la parada es requerido')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    vm.error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),

              // Reason field
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

              // Disable button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          final ok = await vm.disableStop();
                          if (!context.mounted) return;
                          if (!ok) {
                            final msg = vm.error ?? 'Error al deshabilitar parada';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parada deshabilitada')));
                          }
                        },
                  icon: vm.loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.block),
                  label: Text(
                    vm.loading ? 'Deshabilitando...' : 'Deshabilitar Parada',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Disabled stops list
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
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                        if (vm.error != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!)));
                                        } else if (vm.successMessage != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.successMessage!)));
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.green.shade600,
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
                            'Desde: ${_formatDate(stop.disabledAt)}',
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

  Widget _buildNoticeCard(OperarioViewModel vm, NoticeModel notice) {
    final color = _typeColor(notice.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_typeIcon(notice.type), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        notice.type,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(notice.message, style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(
                  _formatDate(notice.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Desactivar aviso',
            onPressed: vm.loading
                ? null
                : () async {
                    await vm.deactivateNotice(notice.id);
                    if (!context.mounted) return;
                    if (vm.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!)));
                    } else if (vm.successMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.successMessage!)));
                    }
                  },
            icon: const Icon(Icons.visibility_off_outlined),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return Icons.campaign_outlined;
      case 'TURISMO':
        return Icons.attractions_outlined;
      case 'LINEA':
        return Icons.route_outlined;
      case 'PARADA':
        return Icons.location_on_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return const Color(0xFF0EA5E9);
      case 'TURISMO':
        return const Color(0xFF16A34A);
      case 'LINEA':
        return const Color(0xFFDC2626);
      case 'PARADA':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
