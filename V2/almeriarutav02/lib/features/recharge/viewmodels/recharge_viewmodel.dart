import 'package:flutter/material.dart';
import 'dart:math';
import '../models/transport_card_model.dart';

class RechargeViewModel extends ChangeNotifier {
  final List<TransportCardModel> _myCards = [];

  List<TransportCardModel> get myCards => _myCards;

  RechargeViewModel() {
    _loadUserCards();
  }

  void _loadUserCards() {
    final now = DateTime.now();

    _myCards.addAll([
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta Saldo Virtual',
        type: CardType.single,
        balance: 15.50,
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
        name: 'Bonobús Universidad',
        type: CardType.bonobus,
        balance: 0,
        active: true,
        expirationType: ExpirationType.schoolYear,
        expirationDate: DateTime(now.year, 9, 30),
      ),
      TransportCardModel(
        id: _id(),
        name: 'Tarjeta +65',
        type: CardType.free,
        balance: 0,
        active: true,
      ),
    ]);
  }

  void rechargeCard(TransportCardModel card, double amount) {
    if (card.type == CardType.single) {
      card.balance += amount;
    } else {
      final fixedAmount = getRechargeAmount(card);
      card.balance = fixedAmount;
      
      if (card.expirationType == ExpirationType.monthly) {
        final now = DateTime.now();
        card.expirationDate = DateTime(now.year, now.month + 1, now.day);
      }
    }

    card.history.add(
      RechargeHistory(
        date: DateTime.now(),
        amount: card.type == CardType.single ? amount : getRechargeAmount(card),
      ),
    );

    notifyListeners();
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
    switch (card.name) {
      case 'Mensual Ordinaria': return 19.55;
      case 'Bonobús Universidad': return 3.35;
      case 'Mensual Estudiante': return 16.55;
      case 'Bonobús Ordinario': return 4.45;
      case 'Bonobús Pensionista': return 1.75;
      case 'Tarjeta Estudiante 10': return 7.15;
      default: return 0.0;
    }
  }

  bool isExpired(TransportCardModel card) {
    if (card.expirationDate == null) return false;
    return DateTime.now().isAfter(card.expirationDate!);
  }

  String _id() {
    final r = Random();
    return List.generate(10, (_) => r.nextInt(9)).join();
  }
}