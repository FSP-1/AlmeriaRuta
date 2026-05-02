import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../viewmodels/map_viewmodel.dart';
import '../models/tourist_place.dart';
import '../utils/tourist_bus_route_planner_models.dart';
import 'tourist_bus_route_sheet.dart';

/// Displays nearby bus stops for a tourist place and allows selecting one for routing.
Future<void> showTouristBusStopsSheet({
  required BuildContext context,
  required TouristPlace place,
  required MapViewModel mapViewModel,
}) async {
  final userLocation = mapViewModel.userLocation;
  if (userLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo obtener tu ubicacion actual')),
    );
    return;
  }

  // Direct walk distance for comparison
  final directWalkMeters = Geolocator.distanceBetween(
    userLocation.latitude,
    userLocation.longitude,
    place.location.latitude,
    place.location.longitude,
  );

  final nearbyStops = mapViewModel.getNearbyTouristStops(place);
  if (nearbyStops.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No hay paradas cercanas a ${place.name}')),
    );
    return;
  }

  final evaluatedStops = nearbyStops
      .map((option) => (option: option, plan: mapViewModel.buildTouristBusRoutePlan(place, option.stop)))
      .toList();

  // Prioritize actual best routes to the tourist point:
  // valid plan first, then shorter total time, fewer transfers, and closer stop to place.
evaluatedStops.sort((a, b) {
  final aPlan = a.plan;
  final bPlan = b.plan;

  if (aPlan == null && bPlan != null) return 1;
  if (aPlan != null && bPlan == null) return -1;

  if (aPlan != null && bPlan != null) {
    // 🔥 PRIORIDAD ABSOLUTA: directos
    final aTransfers = aPlan.segments.length;
    final bTransfers = bPlan.segments.length;

    if (aTransfers != bTransfers) {
      return aTransfers.compareTo(bTransfers);
    }

    // luego score
    return _planPrecisionScore(aPlan)
        .compareTo(_planPrecisionScore(bPlan));
  }

  return a.option.distanceToPlaceMeters
      .compareTo(b.option.distanceToPlaceMeters);
});

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ir en bus a ${place.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Walk comparison banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Caminando directo: ${directWalkMeters.round()} m',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Elige una parada de bajada para calcular la ruta en bus:'),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: evaluatedStops.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final evaluated = evaluatedStops[index];
                  final option = evaluated.option;
                  final plan = evaluated.plan;
                  final linesText = option.servingLines.isEmpty
                      ? 'Sin líneas detectadas'
                      : option.servingLines.map((l) => l.name).take(4).join(' · ');

                  final walkToBoard = plan?.walkToBoardMeters ?? 0;
                  final busTimeText = plan != null
                      ? '🚶 ${walkToBoard.round()} m · 🚌 ${plan.routeStops.length} paradas · ~${plan.totalDurationMinutes} min'
                      : null;
                  final saving = plan != null
                      ? (directWalkMeters - plan.totalDistanceMeters).round()
                      : 0;
                  final savingText = plan != null
                      ? (saving > 0 ? 'Ahorras $saving m vs caminar' : 'Similar a caminar')
                      : 'Sin ruta disponible desde tu posición';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.place,
                      color: plan != null ? Colors.blue : Colors.grey,
                    ),
                    title: Text(option.stop.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${option.distanceToPlaceMeters.round()} m del destino · $linesText'),
                        if (busTimeText != null)
                          Text(
                            '$busTimeText  $savingText',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            savingText,
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    enabled: true,
                    onTap: () async {
                      mapViewModel.focusStopFromExternal(
                        option.stop,
                        lineId: option.servingLines.isNotEmpty ? option.servingLines.first.id : null,
                      );
                      Navigator.pop(sheetContext);
                      if (plan == null) return;
                      await mapViewModel.applyTouristBusRoutePlan(plan);
                      if (!context.mounted) return;
                      await showTouristBusRouteSheet(
                        context: context,
                        place: place,
                        plan: plan,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

double _planPrecisionScore(TouristBusRoutePlan plan) {
  final transferPenalty = (plan.segments.length - 1) * 2000.0; // MUY caro
  final walkPenalty = plan.walkToBoardMeters * 2 +
      plan.walkFromStopToPlaceMeters * 2;

  final busDistance = plan.totalDistanceMeters - 
      (plan.walkToBoardMeters + plan.walkFromStopToPlaceMeters);

  return busDistance + walkPenalty + transferPenalty;
}
