import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/validation/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    test('returns deterministic invalid result when remainingUses is 0', () async {
      final service = ValidationService();

      final result = await service.validateTitle(
        ticketId: 'TK-1',
        type: 'Multiple',
        remainingUses: 0,
      );

      expect(result.ticketId, 'TK-1');
      expect(result.type, 'Multiple');
      expect(result.isValid, isFalse);
      expect(result.message, 'Sin viajes disponibles');
      expect(result.line, 'L18');
      expect(result.busId, 'BUS02');
      expect(result.id, startsWith('VAL'));
    });
  });
}
