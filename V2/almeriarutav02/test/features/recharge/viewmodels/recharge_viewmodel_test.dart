import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/recharge/models/transport_card_model.dart';
import 'package:almeriarutav02/features/recharge/viewmodels/recharge_viewmodel.dart';

TransportCardModel _buildCard(
  String name, {
  CardType type = CardType.single,
  ExpirationType expirationType = ExpirationType.none,
  DateTime? expirationDate,
}) {
  return TransportCardModel(
    id: '1',
    name: name,
    type: type,
    balance: 0,
    active: true,
    expirationType: expirationType,
    expirationDate: expirationDate,
  );
}

void main() {
  group('RechargeViewModel', () {
    test('getRechargeAmount returns the configured tariff per card name', () {
      final vm = RechargeViewModel();

      expect(vm.getRechargeAmount(_buildCard('Mensual Ordinaria')), 19.55);
      expect(vm.getRechargeAmount(_buildCard('Bonobús Universidad')), 3.35);
      expect(vm.getRechargeAmount(_buildCard('Tarjeta +65')), 0.0);
    });

    test('canRecharge and isExpired follow expiration rules', () {
      final vm = RechargeViewModel();
      final monthlySoon = _buildCard(
        'Mensual Ordinaria',
        type: CardType.monthly,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime.now().add(const Duration(hours: 12)),
      );
      final expired = _buildCard(
        'Mensual Ordinaria',
        type: CardType.monthly,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(vm.canRecharge(monthlySoon), isTrue);
      expect(vm.isExpired(expired), isTrue);
    });

    test('rechargeCard increases balance for single cards and stores history amount', () {
      final vm = RechargeViewModel();
      final card = _buildCard(
        'Tarjeta Saldo Virtual',
        type: CardType.single,
      );

      vm.rechargeCard(card, 5.5);

      expect(card.balance, 5.5);
      expect(card.history, hasLength(1));
      expect(card.history.first.amount, 5.5);
    });

    test('rechargeCard sets fixed amount for monthly card and updates expiration', () {
      final vm = RechargeViewModel();
      final card = _buildCard(
        'Mensual Ordinaria',
        type: CardType.monthly,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      vm.rechargeCard(card, 99.0);

      expect(card.balance, 19.55);
      expect(card.expirationDate, isNotNull);
      expect(card.history, hasLength(1));
      expect(card.history.first.amount, 19.55);
    });
  });
}
