import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('exposes expected brand reds', () {
      expect(AppTheme.primaryRed, const Color(0xFFE53E3E));
      expect(AppTheme.lightRed, const Color(0xFFFC8181));
      expect(AppTheme.darkRed, const Color(0xFFC53030));
      expect(AppTheme.backgroundRed, const Color(0xFFFED7D7));
    });

    test('lightTheme uses Material3 and themed app bar/button', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.appBarTheme.backgroundColor, AppTheme.primaryRed);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
      expect(theme.elevatedButtonTheme.style, isNotNull);
      expect(theme.cardTheme.elevation, 4);
    });
  });
}
