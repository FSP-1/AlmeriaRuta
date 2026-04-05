import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/recharge/models/transport_card_model.dart';

void main() {
  group('TransportCardModel', () {
    test('initializes with provided values and defaults history to empty', () {
      final card = TransportCardModel(
        id: 'c1',
        name: 'Bonobus',
        type: CardType.bonobus,
        balance: 12.5,
        active: true,
      );

      expect(card.id, 'c1');
      expect(card.name, 'Bonobus');
      expect(card.type, CardType.bonobus);
      expect(card.balance, 12.5);
      expect(card.active, isTrue);
      expect(card.expirationType, ExpirationType.none);
      expect(card.history, isEmpty);
    });

    test('keeps explicit expiration and history values', () {
      final history = [
        RechargeHistory(
          date: DateTime(2026, 4, 1),
          amount: 10,
        ),
      ];

      final card = TransportCardModel(
        id: 'c2',
        name: 'Mensual',
        type: CardType.monthly,
        balance: 0,
        active: false,
        expirationDate: DateTime(2026, 4, 30),
        expirationType: ExpirationType.monthly,
        history: history,
      );

      expect(card.expirationDate, DateTime(2026, 4, 30));
      expect(card.expirationType, ExpirationType.monthly);
      expect(card.history, hasLength(1));
      expect(card.history.first.amount, 10);
    });
  });
}
