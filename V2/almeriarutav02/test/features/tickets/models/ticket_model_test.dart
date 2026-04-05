import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/tickets/models/ticket_model.dart';

void main() {
  group('TicketModel', () {
    test('defaults remainingUses to quantity when omitted', () {
      final ticket = TicketModel(
        id: 'TK-1',
        type: 'Multiple',
        quantity: 3,
        purchaseDate: DateTime(2026, 4, 5),
        amount: 3.15,
        status: 'Activo',
      );

      expect(ticket.remainingUses, 3);
    });

    test('fromJson and toJson round trip data', () {
      final ticket = TicketModel.fromJson({
        'id': 'TK-2',
        'type': 'Individual',
        'quantity': 1,
        'remainingUses': 1,
        'purchaseDate': '2026-04-05T10:15:00.000',
        'amount': 1.05,
        'status': 'Activo',
      });

      expect(ticket.toJson(), {
        'id': 'TK-2',
        'type': 'Individual',
        'quantity': 1,
        'remainingUses': 1,
        'purchaseDate': '2026-04-05T10:15:00.000',
        'amount': 1.05,
        'status': 'Activo',
      });
    });

    test('copyWith updates only requested fields', () {
      final ticket = TicketModel(
        id: 'TK-3',
        type: 'Multiple',
        quantity: 5,
        remainingUses: 4,
        purchaseDate: DateTime(2026, 4, 5),
        amount: 5.25,
        status: 'Activo',
      );

      final updated = ticket.copyWith(remainingUses: 2, status: 'Usado');

      expect(updated.id, 'TK-3');
      expect(updated.quantity, 5);
      expect(updated.remainingUses, 2);
      expect(updated.status, 'Usado');
    });
  });
}
