import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TicketsHubIntroCard extends StatelessWidget {
  const TicketsHubIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.primaryRed.withValues(alpha: 0.08),
      child: const ListTile(
        leading: Icon(Icons.confirmation_number, color: AppTheme.primaryRed),
        title: Text('Compra, recarga y valida desde aquí'),
        subtitle: Text('Todo lo relacionado con tickets y tarjeta en un único menú.'),
      ),
    );
  }
}

class HubActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final int badgeCount;

  const HubActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = enabled ? color : Colors.grey.shade700;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 3,
          color: enabled ? null : Colors.grey.shade300,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: baseColor.withValues(alpha: 0.12),
              child: Icon(icon, color: baseColor),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled ? null : Colors.grey.shade800,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: enabled ? null : Colors.grey.shade700,
              ),
            ),
            trailing: enabled
                ? const Icon(Icons.chevron_right)
                : Icon(
                    Icons.lock,
                    color: Colors.grey.shade700,
                  ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: 6,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TicketSelectionEmptyState extends StatelessWidget {
  const TicketSelectionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay billetes creados en esta sesión',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteTicketsInfoCard extends StatelessWidget {
  const RemoteTicketsInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.primaryRed.withValues(alpha: 0.08),
      child: const ListTile(
        leading: Icon(Icons.mail_outline, color: AppTheme.primaryRed),
        title: Text('Billetes recibidos por notificación'),
        subtitle: Text('Valida aquí los billetes que te han enviado otros usuarios.'),
      ),
    );
  }
}

class TicketUseCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onUse;

  const TicketUseCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: onUse,
          child: const Text('Usar'),
        ),
      ),
    );
  }
}
