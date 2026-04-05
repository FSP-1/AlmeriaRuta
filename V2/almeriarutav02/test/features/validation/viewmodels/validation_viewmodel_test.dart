import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/tickets/models/ticket_model.dart';
import 'package:almeriarutav02/features/validation/viewmodels/validation_viewmodel.dart';

void main() {
  group('ValidationViewModel', () {
    test('validate without ticket does nothing', () async {
      final vm = ValidationViewModel();

      await vm.validate(ticketId: 'TK-1', type: 'Multiple');

      expect(vm.result, isNull);
      expect(vm.loading, isFalse);
      expect(vm.error, isNull);
    });

    test('validate with ticket and no uses keeps ticket unchanged and sets result', () async {
      final vm = ValidationViewModel();
      vm.setTicket(
        TicketModel(
          id: 'TK-1',
          type: 'Multiple',
          quantity: 2,
          remainingUses: 0,
          purchaseDate: DateTime(2026, 4, 5),
          amount: 2.10,
          status: 'Activo',
        ),
      );

      await vm.validate(ticketId: 'TK-1', type: 'Multiple');

      expect(vm.loading, isFalse);
      expect(vm.error, isNull);
      expect(vm.result, isNotNull);
      expect(vm.result!.isValid, isFalse);
      expect(vm.result!.message, 'Sin viajes disponibles');
      expect(vm.currentTicket, isNotNull);
      expect(vm.currentTicket!.remainingUses, 0);
      expect(vm.currentTicket!.status, 'Activo');
    });

    test('clear removes transient state', () {
      final vm = ValidationViewModel();
      vm.clear();

      expect(vm.result, isNull);
      expect(vm.error, isNull);
    });
  });
}
