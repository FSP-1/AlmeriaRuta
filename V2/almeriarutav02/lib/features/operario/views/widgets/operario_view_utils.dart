import 'package:flutter/material.dart';

IconData operarioTypeIcon(String type) {
  switch (type.toUpperCase()) {
    case 'GENERAL':
      return Icons.campaign_outlined;
    case 'TURISMO':
      return Icons.attractions_outlined;
    case 'LINEA':
      return Icons.route_outlined;
    case 'PARADA':
      return Icons.location_on_outlined;
    default:
      return Icons.info_outline;
  }
}

Color operarioTypeColor(String type) {
  switch (type.toUpperCase()) {
    case 'GENERAL':
      return const Color(0xFF0EA5E9);
    case 'TURISMO':
      return const Color(0xFF16A34A);
    case 'LINEA':
      return const Color(0xFFDC2626);
    case 'PARADA':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF64748B);
  }
}

String operarioFormatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'Hace unos segundos';
  } else if (difference.inMinutes < 60) {
    return 'Hace ${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return 'Hace ${difference.inHours} h';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}
