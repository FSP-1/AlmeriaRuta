import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/models/user_notification.dart';
import '../models/ticket_model.dart';
import 'tickets_hub_widgets.dart';

class TicketSelectionList extends StatelessWidget {
  final bool loadingRemoteTickets;
  final List<UserNotification> remoteOnlyNotifications;
  final List<TicketModel> localTickets;
  final Future<void> Function(UserNotification notification) onUseRemoteTicket;
  final Future<void> Function(TicketModel ticket) onUseLocalTicket;

  const TicketSelectionList({
    super.key,
    required this.loadingRemoteTickets,
    required this.remoteOnlyNotifications,
    required this.localTickets,
    required this.onUseRemoteTicket,
    required this.onUseLocalTicket,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (loadingRemoteTickets)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ...remoteOnlyNotifications.map(
          (notification) {
            final ticket = notification.ticket;
            if (ticket == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TicketUseCard(
                leading: Icon(
                  notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: notification.isRead ? Colors.grey : AppTheme.primaryRed,
                ),
                title: '${ticket.type} - ${ticket.id}',
                subtitle:
                    '${notification.body}\nUsos restantes: ${ticket.remainingUses}\nImporte: ${ticket.amount.toStringAsFixed(2)} €',
                onUse: () => onUseRemoteTicket(notification),
              ),
            );
          },
        ),
        ...localTickets.map(
          (ticket) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TicketUseCard(
              leading: const Icon(Icons.confirmation_number, color: AppTheme.primaryRed),
              title: '${ticket.type} - ${ticket.id}',
              subtitle: 'Usos restantes: ${ticket.remainingUses}\nImporte: ${ticket.amount.toStringAsFixed(2)} €',
              onUse: () => onUseLocalTicket(ticket),
            ),
          ),
        ),
      ],
    );
  }
}
