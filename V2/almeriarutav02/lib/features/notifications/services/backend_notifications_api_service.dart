import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../models/user_notification.dart';

class BackendNotificationsApiService {
  final http.Client _client = http.Client();

  Future<List<UserNotification>> fetchNotifications({
    required String token,
    bool unreadOnly = false,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.authApiBaseUrl}/auth/notifications${unreadOnly ? '?unreadOnly=1' : ''}',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'No se pudieron cargar las notificaciones');
    }

    final items = (data['notifications'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map((item) => UserNotification.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudo marcar la notificación');
    }
  }

  Future<void> deleteNotification({
    required String token,
    required int notificationId,
  }) async {
    final response = await _client.delete(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/notifications/$notificationId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error']?.toString() ?? 'No se pudo eliminar la notificación');
    }
  }

  Future<Map<String, dynamic>?> resolveNotificationPayload({
    required String token,
    required int notificationId,
  }) async {
    final notifications = await fetchNotifications(token: token);
    for (final notification in notifications) {
      if (notification.id == notificationId) {
        return notification.payloadJson;
      }
    }
    return null;
  }
}