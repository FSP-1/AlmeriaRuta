import 'package:flutter/material.dart';
import 'dart:math';
import '../models/recharge_profile_model.dart';
import '../models/transport_card_model.dart';
import '../services/recharge_api_service.dart';

class RechargeViewModel extends ChangeNotifier {
  final List<TransportCardModel> _myCards = [];
  final Map<String, RechargeCardOption> _cardOptionsByKey;
  final Map<String, TransportCardModel> _cardsByName = {};
  final RechargeApiService _apiService;
  final String? _token;
  final bool _isGuest;

  static const List<RechargeCardOption> _cardOptions = [
    RechargeCardOption(
      key: 'saldo_virtual',
      title: 'Tarjeta Saldo Virtual',
      description: 'Recarga libre. Ideal para viajes puntuales sin cuota mensual.',
      rechargeMode: 'saldo',
      ageGroup: 'general',
    ),
    RechargeCardOption(
      key: 'mensual_ordinaria',
      title: 'Mensual Ordinaria',
      description: 'Abono mensual para uso frecuente durante todo el mes.',
      rechargeMode: 'mensual',
      ageGroup: 'general',
    ),
    RechargeCardOption(
      key: 'mensual_estudiante',
      title: 'Mensual Estudiante',
      description: 'Abono mensual para estudiantes durante el mes recargado.',
      rechargeMode: 'mensual',
      ageGroup: 'estudiante',
    ),
    RechargeCardOption(
      key: 'bonobus_universidad',
      title: 'Bonobús Universidad',
      description: 'Modalidad por usos para estudiantes universitarios.',
      rechargeMode: 'bonobus',
      ageGroup: 'estudiante',
      travelCount: 10,
    ),
    RechargeCardOption(
      key: 'bonobus_ordinario',
      title: 'Bonobús Ordinario',
      description: 'Tarjeta bonobús para viajes por usos.',
      rechargeMode: 'bonobus',
      ageGroup: 'general',
      travelCount: 10,
    ),
    RechargeCardOption(
      key: 'tarjeta_estudiante_10',
      title: 'Tarjeta Estudiante 10',
      description: 'Viajes ilimitados durante el mes recargado.',
      rechargeMode: 'mensual',
      ageGroup: 'estudiante',
    ),
    RechargeCardOption(
      key: 'tarjeta_mayor_65',
      title: 'Tarjeta +65',
      description: 'Tarjeta bonificada para mayores de 65 años.',
      rechargeMode: 'gratis',
      ageGroup: '65+',
    ),
    RechargeCardOption(
      key: 'tarjeta_discapacidad_65',
      title: 'Tarjeta Discapacidad 65%',
      description: 'Tarjeta bonificada para discapacidad igual o superior al 65%.',
      rechargeMode: 'gratis',
      ageGroup: 'discapacidad',
    ),
    RechargeCardOption(
      key: 'tarjeta_infantil',
      title: 'Tarjeta Infantil',
      description: 'Tarjeta gratuita para menores en el mes de uso.',
      rechargeMode: 'gratis',
      ageGroup: 'infantil',
    ),
  ];

  static const List<String> _paymentMethods = ['Saldo', 'Android Pay', 'Visa'];
  static const Map<String, double> _tariffsByCardName = {
    'Mensual Ordinaria': 19.55,
    'Bonobús Universidad': 3.35,
    'Mensual Estudiante': 16.55,
    'Bonobús Ordinario': 4.45,
    'Bonobús Pensionista': 1.75,
    'Tarjeta Estudiante 10': 7.15,
  };

  bool _loadingProfile = false;
  bool _profileResolved = false;
  String? _profileError;
  String _selectedCardKey = 'saldo_virtual';
  String _selectedPaymentMethod = 'Saldo';
  bool _hasConfiguredCard = false;
  bool _hasSaldoCard = false;

  List<TransportCardModel> get myCards => _myCards;
  List<RechargeCardOption> get cardOptions => _cardOptions;
  List<String> get paymentMethods => _paymentMethods;
  bool get loadingProfile => _loadingProfile;
  bool get profileResolved => _profileResolved;
  String? get profileError => _profileError;
  bool get isRegisteredUser => _token != null && !_isGuest;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get hasConfiguredCard => _hasConfiguredCard;
  bool get hasSaldoCard => _hasSaldoCard;
  List<String> paymentMethodsForCard(TransportCardModel card) {
    if (card.type == CardType.single) {
      return const ['Android Pay', 'Visa'];
    }
    return _paymentMethods;
  }

  RechargeCardOption get selectedCardOption {
    return _cardOptionsByKey[_selectedCardKey] ?? _cardOptions.first;
  }

  RechargeViewModel({
    String? token,
    bool isGuest = false,
    RechargeApiService? apiService,
  })  : _token = token,
        _isGuest = isGuest,
        _cardOptionsByKey = {
          for (final option in _cardOptions) option.key: option,
        },
        _apiService = apiService ?? RechargeApiService() {
    _loadUserCards();
    _loadUserProfile();
  }

  void _loadUserCards() {
    final now = DateTime.now();

    _myCards.addAll([
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta Saldo Virtual',
        type: CardType.single,
        balance: 0,
        active: true,
      ),
      TransportCardModel(
        id: _id(),
        name: 'Mensual Ordinaria',
        type: CardType.monthly,
        balance: 0,
        active: true,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime(now.year, now.month, now.day + 1),
      ),
      TransportCardModel(
        id: _id(),
        name: 'Mensual Estudiante',
        type: CardType.monthly,
        balance: 0,
        active: true,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime(now.year, now.month, now.day + 1),
      ),
      TransportCardModel(
        id: _id(),
        name: 'Bonobús Universidad',
        type: CardType.bonobus,
        balance: 0,
        active: true,
        expirationType: ExpirationType.schoolYear,
        expirationDate: DateTime(now.year, 9, 30),
      ),
      TransportCardModel(
        id: _id(),
        name: 'Bonobús Ordinario',
        type: CardType.bonobus,
        balance: 0,
        active: true,
      ),
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta Estudiante 10',
        type: CardType.monthly,
        balance: 0,
        active: true,
        expirationType: ExpirationType.monthly,
        expirationDate: DateTime(now.year, now.month, now.day + 1),
      ),
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta +65',
        type: CardType.free,
        balance: 0,
        active: true,
      ),
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta Discapacidad 65%',
        type: CardType.free,
        balance: 0,
        active: true,
      ),
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta Infantil',
        type: CardType.free,
        balance: 0,
        active: true,
      ),
    ]);

    for (final card in _myCards) {
      _cardsByName[card.name] = card;
    }

    _syncSelectionWithCards();
  }

  Future<void> rechargeCard(
    TransportCardModel card,
    double amount, {
    String? paymentMethod,
  }) async {
    _selectedCardKey = _toCardKey(card.name);
    _selectedPaymentMethod = paymentMethod ?? _selectedPaymentMethod;

    final appliedAmount = card.type == CardType.single ? amount : getRechargeAmount(card);
    card.balance = card.type == CardType.single ? card.balance + amount : appliedAmount;

    if (card.type != CardType.single && card.expirationType == ExpirationType.monthly) {
      final now = DateTime.now();
      card.expirationDate = DateTime(now.year, now.month + 1, now.day);
    }

    card.history.add(
      RechargeHistory(
        date: DateTime.now(),
        amount: appliedAmount,
      ),
    );

    notifyListeners();
    await _persistProfile();
  }

  void setSelectedCardOption(RechargeCardOption option) {
    _selectedCardKey = option.key;
    _syncSelectionWithCards();
    notifyListeners();
    _persistProfile();
  }

  void toggleCardOption(String optionKey) {
    _selectedCardKey = _selectedCardKey == optionKey && optionKey != 'saldo_virtual'
        ? 'saldo_virtual'
        : optionKey;
    _syncSelectionWithCards();
    notifyListeners();
    _persistProfile();
  }

  void setSelectedPaymentMethod(String method) {
    if (!_paymentMethods.contains(method)) {
      return;
    }
    _selectedPaymentMethod = method;
    notifyListeners();
    _persistProfile();
  }

  TransportCardModel? cardByOption(RechargeCardOption option) {
    return _cardsByName[option.title];
  }

  List<TransportCardModel> get expiringSoon {
    final now = DateTime.now();
    return _myCards.where((card) {
      if (card.expirationDate == null) return false;
      final diff = card.expirationDate!.difference(now).inDays;
      return diff <= 1 && diff >= -1;
    }).toList();
  }

  bool canRecharge(TransportCardModel card) {
    if (card.type == CardType.single) return true;
    if (card.expirationDate == null) return false;
    final diff = card.expirationDate!.difference(DateTime.now()).inDays;
    return diff <= 1;
  }

  double getRechargeAmount(TransportCardModel card) {
    return _tariffsByCardName[card.name] ?? 0.0;
  }

  bool isExpired(TransportCardModel card) {
    if (card.expirationDate == null) return false;
    return DateTime.now().isAfter(card.expirationDate!);
  }

  String _id() {
    final r = Random();
    return List.generate(10, (_) => r.nextInt(9)).join();
  }

  Future<void> _loadUserProfile() async {
    if (!isRegisteredUser) {
      _profileResolved = true;
      return;
    }

    _loadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      final profile = await _apiService.fetchProfile(token: _token!);
      if (profile != null) {
        _selectedCardKey = profile.cardKey;
        _hasConfiguredCard = profile.configured;
        _hasSaldoCard = profile.hasSaldoCard;

        final saldoCard = _cardsByName['Tarjeta Saldo Virtual'];
        if (saldoCard != null) {
          saldoCard.balance = profile.saldoBalance;
        }

        if (_paymentMethods.contains(profile.paymentMethod)) {
          _selectedPaymentMethod = profile.paymentMethod!;
        }
      }
      _syncSelectionWithCards();
    } catch (e) {
      _profileError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingProfile = false;
      _profileResolved = true;
      notifyListeners();
    }
  }

  bool isExpiringSoon(TransportCardModel card) {
    if (card.expirationDate == null) return false;
    final diff = card.expirationDate!.difference(DateTime.now()).inDays;
    return diff <= 1 && diff >= -1;
  }

  Future<void> _persistProfile() async {
    if (!isRegisteredUser) return;

    final option = selectedCardOption;
    final card = cardByOption(option);
    final saldoCard = _cardsByName['Tarjeta Saldo Virtual'];

    try {
      _hasConfiguredCard = true;
      _hasSaldoCard = _hasSaldoCard || option.key == 'saldo_virtual';

      await _apiService.saveProfile(
        token: _token!,
        profile: RechargeProfileModel(
          cardKey: option.key,
          cardLabel: option.title,
          rechargeMode: option.rechargeMode,
          ageGroup: option.ageGroup,
          travelCount: option.travelCount,
          paymentMethod: _selectedPaymentMethod,
          saldoBalance: saldoCard?.balance ?? 0,
          hasSaldoCard: _hasSaldoCard,
          cardState: (card?.active ?? true) ? 'active' : 'paused',
          configured: true,
        ),
      );
      _profileError = null;
    } catch (e) {
      _profileError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _syncSelectionWithCards() {
    for (final card in _myCards) {
      card.active = _toCardKey(card.name) == _selectedCardKey;
    }
  }

  String _toCardKey(String cardName) {
    for (final option in _cardOptions) {
      if (option.title == cardName) {
        return option.key;
      }
    }
    return 'saldo_virtual';
  }
}