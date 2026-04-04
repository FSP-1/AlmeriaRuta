import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/mobility_service_model.dart';

class HomeInfoCard extends StatelessWidget {
  final MobilityServiceModel service;
  final VoidCallback onTap;

  const HomeInfoCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.icon,
                  size: 32,
                  color: service.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkRed,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Proximamente',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                        fontSize: 10,
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
