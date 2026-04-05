import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/validation/models/validation_model.dart';

void main() {
  group('ValidationModel', () {
    test('stores all constructor fields', () {
      final now = DateTime(2026, 4, 5, 10, 30);
      final model = ValidationModel(
        id: 'VAL123',
        ticketId: 'TK-1',
        type: 'Multiple',
        date: now,
        line: 'L18',
        busId: 'BUS02',
        isValid: true,
        message: 'Viaje validado correctamente',
      );

      expect(model.id, 'VAL123');
      expect(model.ticketId, 'TK-1');
      expect(model.type, 'Multiple');
      expect(model.date, now);
      expect(model.line, 'L18');
      expect(model.busId, 'BUS02');
      expect(model.isValid, isTrue);
      expect(model.message, 'Viaje validado correctamente');
    });
  });
}
