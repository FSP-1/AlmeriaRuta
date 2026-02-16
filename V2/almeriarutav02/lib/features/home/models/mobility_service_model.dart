import 'package:flutter/material.dart';

enum ServiceStatus {
  active,
  comingSoon,
  information,
}

class MobilityServiceModel {
  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final ServiceStatus status;

  const MobilityServiceModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.status,
  });
}
