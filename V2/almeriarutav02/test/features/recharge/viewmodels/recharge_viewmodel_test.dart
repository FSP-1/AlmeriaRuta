import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/recharge/models/recharge_profile_model.dart';
import 'package:almeriarutav02/features/recharge/models/transport_card_model.dart';
import 'package:almeriarutav02/features/recharge/services/recharge_api_service.dart';
import 'package:almeriarutav02/features/recharge/viewmodels/recharge_viewmodel.dart';

class _FakeRechargeApiService extends RechargeApiService {
  _FakeRechargeApiService({this.profileToFetch});

  RechargeProfileModel? profileToFetch;
  String? fetchedToken;
  String? savedToken;
  final List<RechargeProfileModel> savedProfiles = [];

  @override
  Future<RechargeProfileModel?> fetchProfile({required String token}) async {
    fetchedToken = token;
    return profileToFetch;
  }

  @override
  Future<RechargeProfileModel> saveProfile({
    required String token,
    required RechargeProfileModel profile,
  }) async {
    savedToken = token;
    savedProfiles.add(profile);
    return profile;
  }
}

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
  Future<void> flushAsync() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

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

    test('rechargeCard increases balance for single cards and stores history amount', () async {
      final vm = RechargeViewModel();
      final card = _buildCard(
        'Tarjeta Saldo Virtual',
        type: CardType.single,
      );

      await vm.rechargeCard(card, 5.5);

      expect(card.balance, 5.5);
      expect(card.history, hasLength(1));
      expect(card.history.first.amount, 5.5);
    });

    test('rechargeCard sets fixed amount for monthly card and updates expiration', () async {
      final vm = RechargeViewModel();
      final card = _buildCard(
        'Mensual Ordinaria',
        type: CardType.monthly,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      await vm.rechargeCard(card, 99.0);

      expect(card.balance, 19.55);
      expect(card.expirationDate, isNotNull);
      expect(card.history, hasLength(1));
      expect(card.history.first.amount, 19.55);
    });

    test('loads transport profile for registered users and applies selection', () async {
      final fakeApi = _FakeRechargeApiService(
        profileToFetch: const RechargeProfileModel(
          cardKey: 'bonobus_universidad',
          cardLabel: 'Bonobús Universidad',
          rechargeMode: 'bonobus',
          ageGroup: 'estudiante',
          travelCount: 10,
          paymentMethod: 'Visa',
          saldoBalance: 23,
          hasSaldoCard: true,
          cardState: 'active',
          configured: true,
        ),
      );

      final vm = RechargeViewModel(
        token: 'token-test',
        isGuest: false,
        apiService: fakeApi,
      );
      await flushAsync();

      expect(fakeApi.fetchedToken, 'token-test');
      expect(vm.selectedCardOption.key, 'bonobus_universidad');
      expect(vm.selectedPaymentMethod, 'Visa');
      expect(vm.hasConfiguredCard, isTrue);
      expect(vm.hasSaldoCard, isTrue);
      expect(vm.myCards.where((c) => c.active).single.name, 'Bonobús Universidad');
    });

    test('setSelectedPaymentMethod updates only valid values', () {
      final vm = RechargeViewModel();

      vm.setSelectedPaymentMethod('Visa');
      expect(vm.selectedPaymentMethod, 'Visa');

      vm.setSelectedPaymentMethod('Paypal');
      expect(vm.selectedPaymentMethod, 'Visa');
    });

    test('setSelectedCardOption marks selected card as active', () {
      final vm = RechargeViewModel();
      final option = vm.cardOptions.firstWhere((o) => o.key == 'tarjeta_mayor_65');

      vm.setSelectedCardOption(option);

      expect(vm.selectedCardOption.key, 'tarjeta_mayor_65');
      expect(vm.myCards.where((c) => c.active).single.name, 'Tarjeta +65');
    });

    test('toggleCardOption switches between saldo and a single non-saldo option', () {
      final vm = RechargeViewModel();

      vm.toggleCardOption('bonobus_universidad');
      expect(vm.selectedCardOption.key, 'bonobus_universidad');

      vm.toggleCardOption('bonobus_universidad');
      expect(vm.selectedCardOption.key, 'saldo_virtual');
    });

    test('payment methods for saldo card exclude balance payment', () {
      final vm = RechargeViewModel();
      final saldoCard = _buildCard('Tarjeta Saldo Virtual', type: CardType.single);

      expect(vm.paymentMethodsForCard(saldoCard), ['Android Pay', 'Visa']);
    });

    test('rechargeCard persists profile for registered users', () async {
      final fakeApi = _FakeRechargeApiService();
      final vm = RechargeViewModel(
        token: 'token-123',
        isGuest: false,
        apiService: fakeApi,
      );
      await flushAsync();

      final card = vm.myCards.firstWhere((c) => c.name == 'Tarjeta Saldo Virtual');
      vm.setSelectedPaymentMethod('Android Pay');
      await vm.rechargeCard(card, 7.0, paymentMethod: 'Android Pay');

      expect(fakeApi.savedToken, 'token-123');
      expect(fakeApi.savedProfiles, isNotEmpty);
      expect(fakeApi.savedProfiles.last.cardKey, 'saldo_virtual');
      expect(fakeApi.savedProfiles.last.paymentMethod, 'Android Pay');
      expect(fakeApi.savedProfiles.last.rechargeMode, 'saldo');
      expect(fakeApi.savedProfiles.last.hasSaldoCard, isTrue);
    });
  });
}
