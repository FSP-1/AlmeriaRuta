import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';

void main() {
  group('LineModel / StopModel', () {
    test('LineModel.fromJson maps nested stops', () {
      final line = LineModel.fromJson({
        'id': 'L1',
        'name': 'L1',
        'fullName': 'Centro - Hospital',
        'description': 'Ruta urbana',
        'color': '#FF0000',
        'frequency': '15 min',
        'firstService': '06:00',
        'lastService': '23:00',
        'totalStops': 2,
        'stops': [
          {
            'id': '100',
            'name': 'Parada 1',
            'lat': 36.84,
            'lon': -2.45,
            'zone': 'A',
          },
          {
            'id': '101',
            'name': 'Parada 2',
            'lat': 36.85,
            'lon': -2.46,
            'zone': 'B',
          },
        ],
      });

      expect(line.id, 'L1');
      expect(line.color, '#FF0000');
      expect(line.stops, hasLength(2));
      expect(line.stops.first.name, 'Parada 1');
      expect(line.stops.last.zone, 'B');
    });

    test('StopModel.copyWith preserves original fields when omitted', () {
      final stop = StopModel(
        id: '100',
        name: 'Parada 1',
        lat: 36.84,
        lon: -2.45,
        zone: 'A',
        lineIds: {'L1'},
      );

      final updated = stop.copyWith(name: 'Parada 1 - updated');

      expect(updated.id, '100');
      expect(updated.name, 'Parada 1 - updated');
      expect(updated.lat, 36.84);
      expect(updated.lineIds, {'L1'});
    });
  });
}
