import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/tickets/models/ticket_model.dart';
import 'package:almeriarutav02/features/tickets/viewmodels/ticket_viewmodel.dart';

void main() {
  group('TicketViewModel', () {
    test('computes totals based on selected type and quantity', () {
      final vm = TicketViewModel();

      expect(vm.totalPrice, 1.05);

      vm.setType('Multiple');
      vm.setQuantity(4);

      expect(vm.totalPrice, 4.20);
      expect(vm.hasInsufficientBalance, isFalse);
    });

    test('setType Tarjeta resets quantity to 1', () {
      final vm = TicketViewModel();

      vm.setType('Multiple');
      vm.setQuantity(7);
      vm.setType('Tarjeta');

      expect(vm.quantity, 1);
      expect(vm.totalPrice, 10.0);
    });

    test('useTicket decrements or removes ticket', () {
      final vm = TicketViewModel();
      vm.tickets.add(
        TicketModel(
          id: 'T1',
          type: 'Multiple',
          quantity: 2,
          remainingUses: 2,
          purchaseDate: DateTime(2026, 4, 5),
          amount: 2.10,
          status: 'Activo',
        ),
      );

      vm.useTicket('T1');
      expect(vm.tickets.first.remainingUses, 1);

      vm.useTicket('T1');
      expect(vm.tickets, isEmpty);
    });
  });
}
