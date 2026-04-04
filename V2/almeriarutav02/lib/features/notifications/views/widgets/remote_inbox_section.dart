import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/user_notification.dart';

class RemoteInboxSection extends StatelessWidget {
  final List<UserNotification> notifications;
  final Future<void> Function(UserNotification notification) onOpenNotification;

  const RemoteInboxSection({
    super.key,
    required this.notifications,
    required this.onOpenNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Bandeja personal'),
        if (notifications.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('Sin notificaciones pendientes'),
              subtitle: Text('Aqui apareceran los tickets recibidos y otros avisos de cuenta.'),
            ),
          )
        else
          ...notifications.map(
            (notification) => Card(
              child: ListTile(
                onTap: () => onOpenNotification(notification),
                leading: Icon(
                  notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: notification.isRead ? Colors.grey : AppTheme.primaryRed,
                ),
                title: Text(notification.title),
                subtitle: Text(
                  '${notification.body}\n${_formatRemoteDate(notification.createdAt)}',
                ),
                isThreeLine: true,
                trailing: notification.isRead
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: () => onOpenNotification(notification),
                        child: const Text('Abrir'),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatRemoteDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} $hour:$minute';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
