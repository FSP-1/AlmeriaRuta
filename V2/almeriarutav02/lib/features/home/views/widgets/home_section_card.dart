import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/mobility_service_model.dart';

class HomeSectionCard extends StatelessWidget {
  final MobilityServiceModel service;
  final VoidCallback onTap;
  final int unreadNotificationsCount;

  const HomeSectionCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.unreadNotificationsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service.icon,
                  size: 32,
                  color: service.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkRed,
                          ),
                    ),
                    if (service.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: service.color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
              if (service.id == 'notifications' && unreadNotificationsCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadNotificationsCount > 9 ? '9+' : '$unreadNotificationsCount',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
