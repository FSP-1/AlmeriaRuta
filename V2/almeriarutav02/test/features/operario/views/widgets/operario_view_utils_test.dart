import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/operario/views/widgets/operario_view_utils.dart';

void main() {
  group('operario view utils', () {
    test('operarioTypeIcon maps known types', () {
      expect(operarioTypeIcon('GENERAL'), Icons.campaign_outlined);
      expect(operarioTypeIcon('TURISMO'), Icons.attractions_outlined);
      expect(operarioTypeIcon('LINEA'), Icons.route_outlined);
      expect(operarioTypeIcon('PARADA'), Icons.location_on_outlined);
      expect(operarioTypeIcon('otra'), Icons.info_outline);
    });

    test('operarioTypeColor maps known types', () {
      expect(operarioTypeColor('GENERAL'), const Color(0xFF0EA5E9));
      expect(operarioTypeColor('TURISMO'), const Color(0xFF16A34A));
      expect(operarioTypeColor('LINEA'), const Color(0xFFDC2626));
      expect(operarioTypeColor('PARADA'), const Color(0xFFF59E0B));
      expect(operarioTypeColor('otra'), const Color(0xFF64748B));
    });

    test('operarioFormatDate handles recent and older dates', () {
      expect(
        operarioFormatDate(DateTime.now().subtract(const Duration(seconds: 20))),
        'Hace unos segundos',
      );
      expect(
        operarioFormatDate(DateTime.now().subtract(const Duration(minutes: 12))),
        'Hace 12 min',
      );
      expect(
        operarioFormatDate(DateTime.now().subtract(const Duration(hours: 5))),
        'Hace 5 h',
      );

      final older = DateTime(2025, 1, 2);
      expect(operarioFormatDate(older), '2/1/2025');
    });
  });
}
