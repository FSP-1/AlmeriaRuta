import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../models/card_request_admin_record.dart';
import '../models/card_request_record.dart';
import '../models/card_request_submission.dart';

class CardRequestService {
  final http.Client _client;

  CardRequestService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> submit({required String token, required CardRequestSubmission submission}) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me/card-requests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cardId': submission.cardId,
        'payload': submission.toJson(),
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error']?.toString() ?? 'No se pudo enviar la solicitud';
      throw Exception(message);
    }
  }

  Future<List<CardRequestRecord>> listMy({required String token}) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me/card-requests'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error']?.toString() ?? 'No se pudieron cargar solicitudes';
      throw Exception(message);
    }

    final rows = data['requests'] as List? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(CardRequestRecord.fromJson)
        .toList();
  }

  Future<List<CardRequestAdminRecord>> listOperario({
    required String token,
    String? status,
  }) async {
    final uri = Uri.parse('${AppConstants.authApiBaseUrl}/operario/card-requests')
        .replace(queryParameters: status == null ? null : {'status': status});
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error']?.toString() ?? 'No se pudieron cargar solicitudes';
      throw Exception(message);
    }

    final rows = data['requests'] as List? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(CardRequestAdminRecord.fromJson)
        .toList();
  }

  Future<void> decide({
    required String token,
    required int requestId,
    required String status,
    String? reason,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/card-requests/$requestId/decision'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
        'reason': reason,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error']?.toString() ?? 'No se pudo actualizar la solicitud';
      throw Exception(message);
    }
  }
}
