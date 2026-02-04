import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import 'dart:math';

class TicketViewModel extends ChangeNotifier {
  String _selectedType = 'Individual';
  int _quantity = 1;
  String _paymentMethod = 'Google Pay';
  bool _isLoading = false;
  String? _errorMessage;

  final List<TicketModel> _tickets = [];

  // Getters
  String get selectedType => _selectedType;
  int get quantity => _quantity;
  String get paymentMethod => _paymentMethod;
  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // Simular compra
  Future<bool> buyTicket() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simular delay de pago
      await Future.delayed(const Duration(seconds: 2));

      // Simular fallo ocasional (10% probabilidad)
      if (Random().nextInt(10) == 0) {
        throw Exception('Error en el procesamiento del pago');
      }

      final ticket = TicketModel(
        id: _generateId(),
        type: _selectedType,
        quantity: _quantity,
        purchaseDate: DateTime.now(),
        amount: totalPrice,
        status: 'Activo',
      );

      _tickets.add(ticket);
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

  void useTicket(String ticketId) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(status: 'Usado');
      notifyListeners();
    }
  }

  String _generateId() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}