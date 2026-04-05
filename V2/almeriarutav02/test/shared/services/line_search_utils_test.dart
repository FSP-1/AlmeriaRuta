import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';
import 'package:almeriarutav02/shared/services/line_search_utils.dart';

LineModel _buildLine({
  required String id,
  required String name,
  required String fullName,
  required String description,
}) {
  return LineModel(
    id: id,
    name: name,
    fullName: fullName,
    description: description,
    frequency: '15-30 min',
    firstService: '06:30',
    lastService: '22:30',
    totalStops: 1,
    stops: const [],
  );
}

void main() {
  group('LineSearchUtils', () {
    test('normalizeText removes accents and lowercases text', () {
      expect(LineSearchUtils.normalizeText('ÁÉÍÓÚ Ñ'), 'aeiou ñ');
    });

    test('filterLines returns all lines when query is empty', () {
      final lines = [
        _buildLine(id: 'L1', name: 'L1', fullName: 'Centro', description: 'Centro'),
        _buildLine(id: 'L2', name: 'L2', fullName: 'Este', description: 'Este'),
      ];

      final filtered = LineSearchUtils.filterLines(lines, '   ');

      expect(filtered, hasLength(2));
    });

    test('filterLines matches line info and stop matcher fallback', () {
      final lines = [
        _buildLine(id: 'L1', name: 'L1', fullName: 'Centro', description: 'Ruta centro'),
        _buildLine(id: 'L2', name: 'L2', fullName: 'Este', description: 'Ruta este'),
      ];

      final byLineInfo = LineSearchUtils.filterLines(lines, 'centro');
      expect(byLineInfo.map((line) => line.id), ['L1']);

      final byStop = LineSearchUtils.filterLines(
        lines,
        'hospital',
        stopMatcher: (lineId, normalizedQuery) => lineId == 'L2' && normalizedQuery == 'hospital',
      );
      expect(byStop.map((line) => line.id), ['L2']);
    });
  });
}
