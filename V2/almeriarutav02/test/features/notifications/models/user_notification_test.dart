import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/notifications/models/user_notification.dart';

void main() {
  group('UserNotification', () {
    test('fromJson parses base fields and read state variants', () {
      final notification = UserNotification.fromJson({
        'id': '12',
        'title': 'Nuevo ticket',
        'body': 'Has recibido un ticket',
        'is_read': true,
        'created_at': '2026-04-05T10:20:00.000',
      });

      expect(notification.id, 12);
      expect(notification.title, 'Nuevo ticket');
      expect(notification.body, 'Has recibido un ticket');
      expect(notification.isRead, isTrue);
      expect(notification.ticket, isNull);
    });

    test('fromJson parses payload ticket map', () {
      final notification = UserNotification.fromJson({
        'id': 21,
        'title': 'Ticket',
        'body': 'Detalle',
        'isRead': false,
        'created_at': '2026-04-05T11:00:00.000',
        'payloadJson': {
          'ticket': {
            'id': 'TK-77',
            'type': 'Multiple',
            'quantity': 3,
            'remainingUses': 3,
            'purchaseDate': '2026-04-05T10:59:00.000',
            'amount': 3.15,
            'status': 'Activo',
          }
        }
      });

      expect(notification.id, 21);
      expect(notification.isRead, isFalse);
      expect(notification.payloadJson, isNotNull);
      expect(notification.ticket, isNotNull);
      expect(notification.ticket!.id, 'TK-77');
      expect(notification.ticket!.remainingUses, 3);
    });

    test('fromJson applies safe defaults on malformed input', () {
      final notification = UserNotification.fromJson({
        'id': 'x',
        'title': null,
        'body': null,
        'created_at': 'invalid-date',
      });

      expect(notification.id, 0);
      expect(notification.title, '');
      expect(notification.body, '');
      expect(notification.ticket, isNull);
      expect(notification.createdAt, isA<DateTime>());
    });
  });
}
