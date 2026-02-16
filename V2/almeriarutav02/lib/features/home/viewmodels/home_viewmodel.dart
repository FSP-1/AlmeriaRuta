import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';
import '../models/mobility_service_model.dart';
import '../../../core/theme/app_theme.dart';

class HomeViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();
  
  List<LineModel> _lines = [];
  bool _isLoading = false;
  String? _error;

  List<LineModel> get lines => _lines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Servicios principales de autobús
  List<MobilityServiceModel> get busServices => [
    MobilityServiceModel(
      id: 'lines',
      title: 'Líneas de Autobús',
      subtitle: _isLoading 
          ? 'Cargando...' 
          : '${_lines.length} líneas disponibles',
      description: 'Consulta todas las líneas urbanas, horarios y paradas',
      icon: Icons.route,
      color: AppTheme.primaryRed,
      status: ServiceStatus.active,
    ),
    const MobilityServiceModel(
      id: 'tickets',
      title: 'Comprar Tickets',
      subtitle: 'Tickets y tarjeta virtual',
      description: 'Compra tickets individuales, múltiples o tarjeta recargable',
      icon: Icons.credit_card,
      color: Colors.green,
      status: ServiceStatus.active,
    ),
    const MobilityServiceModel(
      id: 'recharge',
      title: 'Recargar Tarjetas',
      subtitle: 'Gestiona tus títulos de transporte',
      description: 'Recarga bonobús, tarjetas mensuales y títulos especiales',
      icon: Icons.account_balance_wallet,
      color: Colors.orange,
      status: ServiceStatus.active,
    ),
    const MobilityServiceModel(
      id: 'map',
      title: 'Mapa Interactivo',
      subtitle: 'Visualiza paradas en tiempo real',
      description: 'Encuentra paradas cercanas con GPS y filtros por zona',
      icon: Icons.map,
      color: Colors.blue,
      status: ServiceStatus.active,
    ),
  ];

  // Servicios de movilidad urbana (informativos)
  List<MobilityServiceModel> get urbanMobilityServices => const [
    MobilityServiceModel(
      id: 'zona_azul',
      title: 'Zona Azul',
      subtitle: null,
      description: 'Información sobre zonas de estacionamiento regulado',
      icon: Icons.local_parking,
      color: Colors.blueAccent,
      status: ServiceStatus.comingSoon,
    ),
    MobilityServiceModel(
      id: 'parkings',
      title: 'Parkings',
      subtitle: null,
      description: 'Localiza parkings públicos y plazas disponibles',
      icon: Icons.garage,
      color: Colors.purple,
      status: ServiceStatus.comingSoon,
    ),
    MobilityServiceModel(
      id: 'bikes',
      title: 'Bicicletas',
      subtitle: null,
      description: 'Servicios de bicicletas públicas y carriles bici',
      icon: Icons.pedal_bike,
      color: Colors.teal,
      status: ServiceStatus.comingSoon,
    ),
    MobilityServiceModel(
      id: 'scooters',
      title: 'Patinetes',
      subtitle: null,
      description: 'Patinetes eléctricos compartidos disponibles',
      icon: Icons.electric_scooter,
      color: Colors.indigo,
      status: ServiceStatus.comingSoon,
    ),
  ];

  // Servicio de notificaciones PRM
  MobilityServiceModel get accessibilityService => const MobilityServiceModel(
    id: 'accessibility',
    title: 'Notificaciones Accesibilidad',
    subtitle: null,
    description: 'Información sobre paradas accesibles (PRM) y zonas de estacionamiento',
    icon: Icons.accessible,
    color: Colors.amber,
    status: ServiceStatus.information,
  );

  Future<void> loadLines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lines = await _apiService.getLines();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<StopModel>> getLineStops(String lineId) async {
    return await _apiService.getLineStops(lineId);
  }
}