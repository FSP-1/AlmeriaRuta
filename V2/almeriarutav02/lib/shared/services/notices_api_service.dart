import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import './line_models.dart';

class NoticesApiService {
  final http.Client _client;

  NoticesApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NoticeModel>> listNotices({String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/notices'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudieron cargar los avisos');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final notices = data['notices'] as List?;
    if (notices == null) return [];

    return notices.map((n) => NoticeModel.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<void> createNotice({
    String? token,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/notices'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'message': message,
        'type': type,
        'relatedId': relatedId,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudo crear el aviso');
    }
  }

  Future<void> deactivateNotice({
    String? token,
    required String noticeId,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/notices/$noticeId/deactivate'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudo desactivar el aviso');
    }
  }

  Future<List<DisabledStopModel>> listDisabledStops({String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/stops/disabled'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudieron cargar las paradas deshabilitadas');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final stops = data['disabledStops'] as List?;
    if (stops == null) return [];

    return stops.map((s) => DisabledStopModel.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<void> disableStop({
    String? token,
    required String stopId,
    required String stopName,
    String? reason,
    int? userId,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/stops/$stopId/disable'),
      headers: headers,
      body: jsonEncode({
        'stopName': stopName,
        'reason': reason,
        'disabledByUserId': userId,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudo deshabilitar la parada');
    }
  }

  Future<void> enableStop({
    String? token,
    required String stopId,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/operario/stops/$stopId/enable'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudo habilitar la parada');
    }
  }
}

class DisabledStopModel {
  final String stopId;
  final String stopName;
  final String reason;
  final DateTime disabledAt;

  DisabledStopModel({
    required this.stopId,
    required this.stopName,
    required this.reason,
    required this.disabledAt,
  });

  factory DisabledStopModel.fromJson(Map<String, dynamic> json) {
    return DisabledStopModel(
      stopId: json['stopId'] ?? '',
      stopName: json['stopName'] ?? '',
      reason: json['reason'] ?? 'No especificado',
      disabledAt: json['disabledAt'] != null
          ? DateTime.parse(json['disabledAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopId': stopId,
      'stopName': stopName,
      'reason': reason,
      'disabledAt': disabledAt.toIso8601String(),
    };
  }
}
