import 'package:flutter/material.dart';

import '../models/coming_soon_mock.dart';

const String comingSoonSubtitle =
    'Disenos de ejemplo. Al tocar cualquier item veras el mensaje Proximamente.';

final Map<String, List<ComingSoonMock>> comingSoonMocksByService = {
  'zona_azul': [
    ComingSoonMock(
      title: 'Mapa de zonas reguladas',
      subtitle: 'Zonas activas por horario',
      description: 'Vista con limites y colores por tarifa',
      icon: Icons.map_outlined,
      color: Colors.blueAccent,
    ),
    ComingSoonMock(
      title: 'Tarifa estimada',
      subtitle: 'Precio segun tiempo',
      description: 'Calculadora rapida por minutos',
      icon: Icons.euro,
      color: Colors.blueAccent,
    ),
    ComingSoonMock(
      title: 'Recordatorio de ticket',
      subtitle: 'Alertas de vencimiento',
      description: 'Notificacion antes de expirar',
      icon: Icons.notifications_active_outlined,
      color: Colors.blueAccent,
    ),
  ],
  'parkings': [
    ComingSoonMock(
      title: 'Disponibilidad en tiempo real',
      subtitle: 'Plazas libres por parking',
      description: 'Mapa con ocupacion',
      icon: Icons.local_parking_outlined,
      color: Colors.purple,
    ),
    ComingSoonMock(
      title: 'Tarifas y horarios',
      subtitle: 'Precios por tramo',
      description: 'Detalles por parking',
      icon: Icons.price_change_outlined,
      color: Colors.purple,
    ),
    ComingSoonMock(
      title: 'Ruta al parking',
      subtitle: 'Navegacion rapida',
      description: 'Ruta optimizada por trafico',
      icon: Icons.directions_car_outlined,
      color: Colors.purple,
    ),
  ],
  'bikes': [
    ComingSoonMock(
      title: 'Estaciones cercanas',
      subtitle: 'Bicis disponibles',
      description: 'Mapa de estaciones',
      icon: Icons.pedal_bike_outlined,
      color: Colors.teal,
    ),
    ComingSoonMock(
      title: 'Estado de anclajes',
      subtitle: 'Huecos libres',
      description: 'Capacidad por estacion',
      icon: Icons.anchor_outlined,
      color: Colors.teal,
    ),
    ComingSoonMock(
      title: 'Rutas recomendadas',
      subtitle: 'Carriles bici',
      description: 'Trayectos seguros',
      icon: Icons.route_outlined,
      color: Colors.teal,
    ),
  ],
  'scooters': [
    ComingSoonMock(
      title: 'Zona operativa',
      subtitle: 'Limites de uso',
      description: 'Mapa con zonas seguras',
      icon: Icons.my_location_outlined,
      color: Colors.indigo,
    ),
    ComingSoonMock(
      title: 'Patinetes cerca',
      subtitle: 'Disponibilidad actual',
      description: 'Lista por distancia',
      icon: Icons.electric_scooter_outlined,
      color: Colors.indigo,
    ),
    ComingSoonMock(
      title: 'Reserva rapida',
      subtitle: 'Bloquea por minutos',
      description: 'Inicio con un toque',
      icon: Icons.lock_clock_outlined,
      color: Colors.indigo,
    ),
  ],
  'accessibility': [
    ComingSoonMock(
      title: 'Paradas accesibles',
      subtitle: 'Mapa PRM',
      description: 'Filtra por accesibilidad',
      icon: Icons.accessible_forward_outlined,
      color: Colors.amber,
    ),
    ComingSoonMock(
      title: 'Alertas de elevadores',
      subtitle: 'Estado de accesos',
      description: 'Avisos de incidencias',
      icon: Icons.warning_amber_outlined,
      color: Colors.amber,
    ),
    ComingSoonMock(
      title: 'Asistencia en ruta',
      subtitle: 'Solicitudes PRM',
      description: 'Ayuda al conductor',
      icon: Icons.support_agent_outlined,
      color: Colors.amber,
    ),
  ],
};
