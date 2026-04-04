import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';

class TicketPurchaseApiService {
  final http.Client _client = http.Client();

  Future<void> validateRecipient({
    required String token,
    required String recipientIdentifier,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/tickets/purchase'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipientIdentifier': recipientIdentifier,
        'validateOnly': true,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'Destinatario no valido');
    }
  }

  Future<void> notifyTicketPurchase({
    required String token,
    required String recipientIdentifier,
    required String type,
    required int quantity,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/tickets/purchase'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipientIdentifier': recipientIdentifier,
        'type': type,
        'quantity': quantity,
        'amount': amount,
        'paymentMethod': paymentMethod,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'No se pudo notificar la compra');
    }
  }
}