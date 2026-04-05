import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:almeriarutav02/features/tickets/services/ticket_purchase_api_service.dart';

void main() {
  group('TicketPurchaseApiService', () {
    test('validateRecipient succeeds on 2xx response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer token-1');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['recipientIdentifier'], 'user@example.com');
        expect(body['validateOnly'], isTrue);
        return http.Response('{"ok":true}', 200);
      });

      final service = TicketPurchaseApiService(client: client);

      await service.validateRecipient(
        token: 'token-1',
        recipientIdentifier: 'user@example.com',
      );
    });

    test('validateRecipient throws backend error message on non-2xx', () async {
      final client = MockClient((request) async {
        return http.Response('{"error":"Destinatario no encontrado"}', 400);
      });

      final service = TicketPurchaseApiService(client: client);

      expect(
        () => service.validateRecipient(
          token: 'token-1',
          recipientIdentifier: 'missing@example.com',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Destinatario no encontrado'),
          ),
        ),
      );
    });

    test('notifyTicketPurchase posts payload and succeeds on 2xx', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['recipientIdentifier'], 'friend@example.com');
        expect(body['type'], 'bonobus');
        expect(body['quantity'], 2);
        expect(body['amount'], 2.8);
        expect(body['paymentMethod'], 'wallet');
        return http.Response('{"ok":true}', 201);
      });

      final service = TicketPurchaseApiService(client: client);

      await service.notifyTicketPurchase(
        token: 'token-1',
        recipientIdentifier: 'friend@example.com',
        type: 'bonobus',
        quantity: 2,
        amount: 2.8,
        paymentMethod: 'wallet',
      );
    });

    test('notifyTicketPurchase throws fallback message when backend omits error', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"fail"}', 500);
      });

      final service = TicketPurchaseApiService(client: client);

      expect(
        () => service.notifyTicketPurchase(
          token: 'token-1',
          recipientIdentifier: 'friend@example.com',
          type: 'bonobus',
          quantity: 1,
          amount: 1.4,
          paymentMethod: 'wallet',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No se pudo notificar la compra'),
          ),
        ),
      );
    });
  });
}
