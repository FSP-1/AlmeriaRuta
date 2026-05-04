import 'package:flutter/material.dart';

import '../../utils/tourist_bus_route_planner.dart';

class SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const SummaryChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class SegmentCard extends StatelessWidget {
  final int segmentIndex;
  final TouristBusSegment segment;
  final bool isLast;

  const SegmentCard({
    super.key,
    required this.segmentIndex,
    required this.segment,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = segmentIndex.isEven ? Colors.blue : Colors.deepPurple;
    final routeCount = segment.routeStops.length;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${segmentIndex + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Línea ${segment.line.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${segment.boardingStop.name} → ${segment.destinationStop.name}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                if (isLast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Final',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SummaryChip(label: 'Subida', value: segment.boardingStop.name),
                SummaryChip(label: 'Bajada', value: segment.destinationStop.name),
                SummaryChip(label: 'Paradas', value: '$routeCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransferBanner extends StatelessWidget {
  const TransferBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_calls, color: Colors.deepPurple.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Transbordo: cambia de línea aquí y sigue el siguiente tramo.',
              style: TextStyle(
                color: Colors.deepPurple.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}