import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ticket_model.dart';
import 'dart:math';

class TicketViewModel extends ChangeNotifier {
  static const _ticketsKey = 'local_tickets';
  String _selectedType = 'Individual';
  int _quantity = 1;
  String _paymentMethod = 'Google Pay';
  bool _isLoading = false;
  String? _errorMessage;
  double _balance = 15.50; // Saldo simulado
  bool _ticketsLoaded = false;

  final List<TicketModel> _tickets = [];

  // Getters
  String get selectedType => _selectedType;
  int get quantity => _quantity;
  String get paymentMethod => _paymentMethod;
  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _balance;

  double get totalPrice {
    switch (_selectedType) {
      case 'Individual':
        return 1.05;
      case 'Multiple':
        return 1.05 * _quantity;
      case 'Tarjeta':
        return 10.00;
      default:
        return 0;
    }
  }

  bool get hasInsufficientBalance => _balance < totalPrice;

  // Setters
  void setType(String type) {
    _selectedType = type;
    if (type == 'Tarjeta') {
      _quantity = 1;
    }
    notifyListeners();
  }

  void setQuantity(int q) {
    if (q >= 1 && q <= 99) {
      _quantity = q;
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadTickets() async {
    if (_ticketsLoaded) return;
    _ticketsLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    final rawTickets = prefs.getStringList(_ticketsKey) ?? const [];

    _tickets.clear();
    for (final raw in rawTickets) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _tickets.add(TicketModel.fromJson(data));
      } catch (_) {
        // Skip malformed entries instead of failing the whole load.
      }
    }
    notifyListeners();
  }

  Future<void> persistTicketsState() async {
    await _saveTickets();
    notifyListeners();
  }

  // Simular compra. En modo regalo puede procesar pago sin crear ticket local.
  Future<bool> buyTicket({bool createLocalTicket = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verificar saldo si se paga con saldo
      if (_paymentMethod == 'Saldo' && hasInsufficientBalance) {
        throw Exception('Saldo insuficiente para realizar la compra');
      }

      // Simular delay de pago
      await Future.delayed(const Duration(seconds: 2));

      // Simular fallo ocasional (10% probabilidad)
      if (Random().nextInt(10) == 0) {
        throw Exception('Error en el procesamiento del pago');
      }

      // Descontar del saldo si se paga con saldo
      if (_paymentMethod == 'Saldo') {
        _balance -= totalPrice;
      }

      if (createLocalTicket) {
        final ticket = TicketModel(
          id: _generateId(),
          type: _selectedType,
          quantity: _quantity,
          purchaseDate: DateTime.now(),
          amount: totalPrice,
          status: 'Activo',
        );

        _tickets.add(ticket);
        await _saveTickets();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> useTicket(String ticketId) async {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final ticket = _tickets[index];
      if (ticket.remainingUses > 1) {
        ticket.remainingUses--;
      } else {
        _tickets.removeAt(index);
      }
      await _saveTickets();
      notifyListeners();
    }
  }

  Future<void> _saveTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _tickets.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_ticketsKey, data);
  }

  String _generateId() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}