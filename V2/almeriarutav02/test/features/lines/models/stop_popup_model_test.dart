import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/lines/models/stop_popup_model.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';

void main() {
  group('StopPopupModel', () {
    test('stores stop, zone name and passing lines', () {
      final stop = StopModel(
        id: '100',
        name: 'Parada Centro',
        lat: 36.84,
        lon: -2.46,
        zone: 'A',
      );
      final line = LineModel(
        id: 'L1',
        name: 'L1',
        fullName: 'Linea 1',
        description: 'Centro - Universidad',
        frequency: '15 min',
        firstService: '06:30',
        lastService: '22:30',
        totalStops: 1,
        stops: const [],
      );

      final model = StopPopupModel(
        stop: stop,
        zoneName: 'Centro',
        passingLines: [line],
      );

      expect(model.stop.id, '100');
      expect(model.zoneName, 'Centro');
      expect(model.passingLines, hasLength(1));
      expect(model.passingLines.first.id, 'L1');
    });
  });
}
