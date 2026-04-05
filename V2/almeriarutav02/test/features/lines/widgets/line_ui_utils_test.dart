import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/core/theme/app_theme.dart';
import 'package:almeriarutav02/features/lines/widgets/line_ui_utils.dart';

void main() {
  group('LineUiUtils', () {
    test('parseLineColor returns primary color for null or invalid value', () {
      expect(LineUiUtils.parseLineColor(null), AppTheme.primaryRed);
      expect(LineUiUtils.parseLineColor('ZZZZZZ'), AppTheme.primaryRed);
      expect(LineUiUtils.parseLineColor('#12345'), AppTheme.primaryRed);
    });

    test('parseLineColor parses #RRGGBB and AARRGGBB formats', () {
      expect(LineUiUtils.parseLineColor('#112233'), const Color(0xFF112233));
      expect(LineUiUtils.parseLineColor('80112233'), const Color(0x80112233));
    });

    test('resolveZoneName returns a known zone for known coordinates', () {
      final zone = LineUiUtils.resolveZoneName(36.8385, -2.4630);
      expect(zone, isNotEmpty);
      expect(zone, isNot('Sin zona definida'));
    });
  });
}
