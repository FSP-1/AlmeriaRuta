import 'package:flutter/material.dart';

import '../../models/tourist_place.dart';
import '../../utils/tourist_bus_route_planner.dart';
import '../tourist_instructions_formatter.dart';
import 'tourist_bus_route_sheet_components.dart';

class TouristBusRouteSheetContent extends StatelessWidget {
  final TouristPlace place;
  final TouristBusRoutePlan plan;
  final VoidCallback onClose;

  const TouristBusRouteSheetContent({
    super.key,
    required this.place,
    required this.plan,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final instructions = buildBusRouteInstructions(plan, place);
    final totalStops = plan.routeStops.length;
    final transferCount = plan.segments.length - 1;
    final hasTransfer = plan.hasTransfer;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.route, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ruta en bus a ${place.name}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Te mostramos el recorrido paso a paso, sin saturarte con paradas largas.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SummaryChip(label: 'Líneas', value: plan.linesLabel),
                    SummaryChip(label: 'Transbordos', value: '$transferCount'),
                    SummaryChip(label: 'Subida', value: plan.boardingStop.name),
                    SummaryChip(label: 'Bajada', value: plan.destinationStop.name),
                    SummaryChip(label: 'Paradas bus', value: '$totalStops'),
                    SummaryChip(label: 'Caminata inicio', value: '${plan.walkToBoardMeters.round()} m'),
                    SummaryChip(label: 'Caminata final', value: '${plan.walkFromStopToPlaceMeters.round()} m'),
                    SummaryChip(label: 'Distancia total', value: '${plan.totalDistanceMeters.round()} m'),
                  ],
                ),
                if (hasTransfer) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hay transbordo: el recorrido se divide en ${plan.segments.length} tramos visuales para que sea más fácil seguirlo.',
                            style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Tramos del recorrido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...List.generate(plan.segments.length, (index) {
                  final segment = plan.segments[index];
                  final isLast = index == plan.segments.length - 1;
                  return Column(
                    children: [
                      SegmentCard(
                        segmentIndex: index,
                        segment: segment,
                        isLast: isLast,
                      ),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: TransferBanner(),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Instrucciones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...List.generate(instructions.length, (index) {
                  final step = instructions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 0,
                      color: index.isEven ? Colors.grey.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(fontSize: 14, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    'Paradas del recorrido ($totalStops)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    totalStops > 8
                        ? 'Lista completa ocultable para rutas largas'
                        : 'Lista completa del trayecto',
                  ),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        plan.routeStops.length,
                        (i) {
                          final stop = plan.routeStops[i];
                          final isFirst = i == 0;
                          final isLast = i == plan.routeStops.length - 1;
                          final label = isFirst
                              ? 'Subida'
                              : (isLast ? 'Bajada' : 'Intermedia');

                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: isFirst
                                  ? Colors.deepOrange.shade100
                                  : (isLast ? Colors.green.shade100 : Colors.blue.shade100),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isFirst
                                      ? Colors.deepOrange.shade900
                                      : (isLast ? Colors.green.shade900 : Colors.blue.shade900),
                                ),
                              ),
                            ),
                            label: Text('${stop.name} · $label'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onClose,
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}