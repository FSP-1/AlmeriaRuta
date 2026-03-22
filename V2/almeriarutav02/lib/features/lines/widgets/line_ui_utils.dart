import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/models/zone_model.dart';

class LineUiUtils {
  static String resolveZoneName(double lat, double lon) {
    final zone = AlmeriaZones.findZoneByLatLng(LatLng(lat, lon));
    return zone?.name ?? 'Sin zona definida';
  }

  static Color parseLineColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppTheme.primaryRed;
    }

    try {
      String cleanColor = colorString.replaceFirst('#', '');
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      } else if (cleanColor.length != 8) {
        return AppTheme.primaryRed;
      }
      return Color(int.parse('0x$cleanColor'));
    } catch (_) {
      return AppTheme.primaryRed;
    }
  }
}