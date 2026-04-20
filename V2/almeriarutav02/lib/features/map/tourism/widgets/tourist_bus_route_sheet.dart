import 'package:flutter/material.dart';

import '../models/tourist_place.dart';
import '../utils/tourist_bus_route_planner.dart';
import 'tourist_instructions_formatter.dart';

/// Displays the complete bus route plan with step-by-step instructions.
Future<void> showTouristBusRouteSheet({
  required BuildContext context,
  required TouristPlace place,
  required TouristBusRoutePlan plan,
}) {
  final instructions = buildBusRouteInstructions(plan, place);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ruta en bus a ${place.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Líneas: ${plan.linesLabel}'),
              Text('Transbordos: ${plan.segments.length - 1}'),
              Text('Sube en: ${plan.boardingStop.name}'),
              Text('Baja en: ${plan.destinationStop.name}'),
              Text('Paradas del bus: ${plan.routeStops.length}'),
              Text('Caminata inicial: ${plan.walkToBoardMeters.round()} m'),
              Text('Caminata final: ${plan.walkFromStopToPlaceMeters.round()} m'),
              Text('Tiempo estimado: ${plan.totalDurationMinutes} min'),
              const SizedBox(height: 12),
              const Text(
                'Instrucciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...instructions.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Paradas del recorrido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.routeStops
                    .map(
                      (stop) => Chip(
                        label: Text(stop.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
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
