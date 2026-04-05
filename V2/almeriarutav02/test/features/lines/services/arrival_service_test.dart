import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/lines/services/arrival_service.dart';

void main() {
  group('ArrivalService', () {
    test('getArrivalMinutes returns value in expected range', () {
      final minutes = ArrivalService.getArrivalMinutes('100', 'L1');

      expect(minutes, greaterThanOrEqualTo(1));
      expect(minutes, lessThanOrEqualTo(ArrivalService.baseMinutes));
    });

    test('getArrivalMinutes is deterministic for same stop and line in same instant', () {
      final first = ArrivalService.getArrivalMinutes('100', 'L1');
      final second = ArrivalService.getArrivalMinutes('100', 'L1');

      expect(second, inInclusiveRange(first - 1, first + 1));
    });

    test('formatArrivalLabel maps minute ranges correctly', () {
      expect(ArrivalService.formatArrivalLabel(1), 'Llegando');
      expect(ArrivalService.formatArrivalLabel(3), 'Inminente');
      expect(ArrivalService.formatArrivalLabel(8), '8 min');
    });

    test('formatArrivalLabel keeps lowest bucket for non-positive values', () {
      expect(ArrivalService.formatArrivalLabel(0), 'Llegando');
      expect(ArrivalService.formatArrivalLabel(-2), 'Llegando');
    });

    test('max baseMinutes still returns numeric label', () {
      expect(
        ArrivalService.formatArrivalLabel(ArrivalService.baseMinutes),
        '${ArrivalService.baseMinutes} min',
      );
    });
  });
}
