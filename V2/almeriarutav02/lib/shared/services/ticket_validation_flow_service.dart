import 'package:flutter/material.dart';

import '../../features/notifications/models/user_notification.dart';
import '../../features/notifications/services/backend_notifications_api_service.dart';
import '../../features/tickets/models/ticket_model.dart';
import '../../features/validation/views/validate_trip_view.dart';

class TicketValidationFlowResult {
  final bool wasUsed;
  final bool isExhausted;

  const TicketValidationFlowResult({
    required this.wasUsed,
    required this.isExhausted,
  });
}

class TicketValidationFlowService {
  final BackendNotificationsApiService _notificationsApi;

  TicketValidationFlowService({BackendNotificationsApiService? notificationsApi})
      : _notificationsApi = notificationsApi ?? BackendNotificationsApiService();

  Future<List<UserNotification>> fetchActiveRemoteTicketNotifications({
    required String? token,
    required bool isAuthenticated,
    required bool isGuest,
  }) async {
    if (token == null || !isAuthenticated || isGuest) {
      return const [];
    }

    final notifications = await _notificationsApi.fetchNotifications(token: token);
    return notifications
        .where((n) => n.ticket != null && n.ticket!.remainingUses > 0)
        .toList();
  }

  int totalUnusedTickets({
    required List<TicketModel> localTickets,
    required List<UserNotification> remoteNotifications,
  }) {
    final localIds = localTickets.map((t) => t.id).toSet();
    final remoteOnlyCount = remoteNotifications
        .where((n) => n.ticket != null && !localIds.contains(n.ticket!.id))
        .length;
    return localTickets.length + remoteOnlyCount;
  }

  Future<TicketValidationFlowResult> openValidationFlow({
    required BuildContext context,
    required TicketModel ticket,
  }) async {
    final initialRemainingUses = ticket.remainingUses;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ValidateTripView(ticket: ticket),
      ),
    );

    final wasUsed = ticket.remainingUses < initialRemainingUses;
    return TicketValidationFlowResult(
      wasUsed: wasUsed,
      isExhausted: ticket.remainingUses <= 0,
    );
  }

  Future<void> markNotificationAsRead({
    required String? token,
    required int notificationId,
  }) async {
    if (token == null) return;
    await _notificationsApi.markAsRead(token: token, notificationId: notificationId);
  }

  Future<void> deleteNotification({
    required String? token,
    required int notificationId,
  }) async {
    if (token == null) return;
    await _notificationsApi.deleteNotification(token: token, notificationId: notificationId);
  }
}
