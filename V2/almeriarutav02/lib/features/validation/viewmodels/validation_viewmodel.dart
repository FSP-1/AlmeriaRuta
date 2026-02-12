import 'package:flutter/material.dart';
import '../models/validation_model.dart';
import '../services/validation_service.dart';
import '../../tickets/models/ticket_model.dart';

class ValidationViewModel extends ChangeNotifier {
  final ValidationService _service = ValidationService();

  ValidationModel? _result;
  bool _loading = false;
  String? _error;
  TicketModel? _currentTicket;

  ValidationModel? get result => _result;
  bool get loading => _loading;
  String? get error => _error;
  TicketModel? get currentTicket => _currentTicket;

  void setTicket(TicketModel ticket) {
    _currentTicket = ticket;
    notifyListeners();
  }

  Future<void> validate({
    required String ticketId,
    required String type,
  }) async {
    if (_currentTicket == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _service.validateTitle(
        ticketId: ticketId,
        type: type,
        remainingUses: _currentTicket!.remainingUses,
      );

      if (_result!.isValid && _currentTicket!.remainingUses > 0) {
        _currentTicket!.remainingUses--;
        if (_currentTicket!.remainingUses == 0) {
          _currentTicket = _currentTicket!.copyWith(status: 'Usado');
        }
      }
    } catch (e) {
      _error = "Error al validar";
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}