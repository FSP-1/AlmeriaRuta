import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/map/models/filter_mode.dart';

void main() {
  group('MapFilter', () {
    test('named constructors set expected modes and lineId', () {
      const nearby = MapFilter.nearby();
      const all = MapFilter.all();
      const favorites = MapFilter.favorites();
      final line = MapFilter.line('L1');

      expect(nearby.mode, FilterMode.nearby);
      expect(all.mode, FilterMode.all);
      expect(favorites.mode, FilterMode.favorites);
      expect(line.mode, FilterMode.line);
      expect(line.lineId, 'L1');
    });

    test('toString maps labels by mode', () {
      expect(const MapFilter.nearby().toString(), 'Cercanas');
      expect(const MapFilter.all().toString(), 'Todas');
      expect(const MapFilter.favorites().toString(), 'Favoritas');
      expect(MapFilter.line('L18').toString(), 'L18');
      expect(const MapFilter(mode: FilterMode.line).toString(), 'Línea');
    });
  });
}
