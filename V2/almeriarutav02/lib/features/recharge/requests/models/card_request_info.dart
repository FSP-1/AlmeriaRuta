import 'package:flutter/material.dart';

class CardRequestInfo {
  final String id;
  final String title;
  final String shortDescription;
  final String priceLabel;
  final String acquisition;
  final String extraInfo;
  final IconData icon;
  final Color color;
  final List<String> details;
  final List<String> requirements;
  final List<String> documents;
  final List<String> whereToSubmit;
  final List<String> conditions;

  const CardRequestInfo({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.priceLabel,
    required this.acquisition,
    required this.extraInfo,
    required this.icon,
    required this.color,
    required this.details,
    required this.requirements,
    required this.documents,
    required this.whereToSubmit,
    required this.conditions,
  });
}
