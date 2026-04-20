import 'package:flutter/material.dart';
import '../../../shared/services/line_models.dart';
import '../tourism/utils/tourist_bus_route_planner.dart';
import '../tourism/models/tourist_place.dart';
import '../tourism/widgets/tourist_bus_route_sheet.dart';

/// Bottom sheet shown when tapping a stop during tourist bus route mode.
class TouristBusStopInfoSheet extends StatelessWidget {
  final StopModel stop;
  final TouristBusRoutePlan? plan;
  final TouristPlace? selectedPlace;

  const TouristBusStopInfoSheet({
    super.key,
    required this.stop,
    required this.plan,
    required this.selectedPlace,
  });

  @override
  Widget build(BuildContext context) {
    final isBoardingStop = plan?.boardingStop.id == stop.id;
    final isDestinationStop = plan?.destinationStop.id == stop.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isBoardingStop
                  ? 'Parada de subida al bus ${plan?.line.name ?? ''}'
                  : isDestinationStop
                      ? 'Parada para bajar cerca del punto turístico'
                      : 'Parada intermedia del recorrido',
            ),
            const SizedBox(height: 8),
            Text('Líneas: ${stop.lineIds.join(' · ')}'),
            if (plan != null && selectedPlace != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showTouristBusRouteSheet(
                    context: context,
                    place: selectedPlace!,
                    plan: plan!,
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Ver instrucciones del recorrido'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
