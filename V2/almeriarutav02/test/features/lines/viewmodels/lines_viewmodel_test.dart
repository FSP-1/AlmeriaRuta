import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:almeriarutav02/features/lines/viewmodels/lines_viewmodel.dart';
import 'package:almeriarutav02/features/map/models/zone_model.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';

void main() {
  group('LinesViewModel', () {
    test('formatArrivalLabel maps null and minute thresholds', () {
      final vm = LinesViewModel();

      expect(vm.formatArrivalLabel(null), '--');
      expect(vm.formatArrivalLabel(1), 'Llegando');
      expect(vm.formatArrivalLabel(3), 'Inminente');
      expect(vm.formatArrivalLabel(9), '9 min');
    });

    test('resolveLinesPassingStopUsingMapData falls back to current line when no lineIds', () {
      final vm = LinesViewModel();
      final currentLine = _line('L1', 'L1');
      final stop = StopModel(
        id: '100',
        name: 'Parada Centro',
        lat: 36.84,
        lon: -2.46,
        zone: 'A',
      );

      final result = vm.resolveLinesPassingStopUsingMapData(stop, currentLine, [stop]);

      expect(result, hasLength(1));
      expect(result.first.id, 'L1');
    });

    test('buildStopPopupData with aggregated stops populates zone and includes current line fallback', () async {
      final vm = LinesViewModel();
      final currentLine = _line('L1', 'L1');
      final stop = StopModel(
        id: '100',
        name: 'Parada Centro',
        lat: 36.8385,
        lon: -2.4630,
        zone: 'A',
      );

      final popup = await vm.buildStopPopupData(
        stop,
        currentLine,
        aggregatedStops: [
          stop.copyWith(lineIds: {'L1'}),
        ],
      );

      expect(popup.stop.id, '100');
      expect(popup.passingLines, isNotEmpty);
      expect(popup.passingLines.first.id, 'L1');
      expect(popup.zoneName, isNot('Sin zona definida'));
      expect(AlmeriaZones.findZoneByLatLng(const LatLng(36.8385, -2.4630)), isNotNull);
    });

    test('resolveLinesPassingStopUsingMapData supports nearby-name matching branch', () {
      final vm = LinesViewModel();
      final currentLine = _line('L1', 'L1');
      final stop = StopModel(
        id: '100',
        name: 'Parada Centro',
        lat: 36.8400,
        lon: -2.4600,
        zone: 'A',
      );

      final result = vm.resolveLinesPassingStopUsingMapData(stop, currentLine, [
        StopModel(
          id: '200',
          name: 'Parada Centro',
          lat: 36.8402,
          lon: -2.4602,
          zone: 'A',
          lineIds: const {},
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.first.id, 'L1');
    });

    test('resolveLinesPassingStopUsingMapData falls back when no id or nearby-name match', () {
      final vm = LinesViewModel();
      final currentLine = _line('L1', 'L1');
      final stop = StopModel(
        id: '100',
        name: 'Parada Centro',
        lat: 36.84,
        lon: -2.46,
        zone: 'A',
      );

      final result = vm.resolveLinesPassingStopUsingMapData(stop, currentLine, [
        StopModel(
          id: '999',
          name: 'Otra parada',
          lat: 36.90,
          lon: -2.50,
          zone: 'A',
          lineIds: const {'L2'},
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.first.id, 'L1');
    });
  });
}

LineModel _line(String id, String name) {
  return LineModel(
    id: id,
    name: name,
    fullName: name,
    description: 'Linea $name',
    frequency: '15 min',
    firstService: '06:30',
    lastService: '22:30',
    totalStops: 1,
    stops: const [],
  );
}
