import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/home/models/mobility_service_model.dart';

void main() {
  group('MobilityServiceModel', () {
    test('stores constructor fields including optional subtitle', () {
      const model = MobilityServiceModel(
        id: 'bus',
        title: 'Autobus urbano',
        subtitle: 'Lineas y horarios',
        description: 'Consulta lineas disponibles',
        icon: Icons.directions_bus,
        color: Colors.red,
        status: ServiceStatus.active,
      );

      expect(model.id, 'bus');
      expect(model.title, 'Autobus urbano');
      expect(model.subtitle, 'Lineas y horarios');
      expect(model.description, 'Consulta lineas disponibles');
      expect(model.icon, Icons.directions_bus);
      expect(model.color, Colors.red);
      expect(model.status, ServiceStatus.active);
    });

    test('supports null subtitle for compact cards', () {
      const model = MobilityServiceModel(
        id: 'future',
        title: 'Servicio futuro',
        description: 'Pendiente de lanzamiento',
        icon: Icons.new_releases,
        color: Colors.orange,
        status: ServiceStatus.comingSoon,
      );

      expect(model.subtitle, isNull);
      expect(model.status, ServiceStatus.comingSoon);
    });
  });
}
