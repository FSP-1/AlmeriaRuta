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
      title: 'Billetes y tarjeta',
      subtitle: 'Compra, recarga y valida',
      description: 'Compra billetes, recarga tarjetas y valida o usa tus títulos',
      icon: Icons.confirmation_number,
      color: Colors.green,
      status: ServiceStatus.active,
    ),
    const MobilityServiceModel(
      id: 'notifications',
      title: 'Notificaciones',
      subtitle: 'Configura tus avisos',
      description: 'Recordatorios de recarga y avisos de llegada a paradas',
      icon: Icons.notifications_active,
      color: Colors.deepPurple,
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

  Future<void> loadLines({bool forceRefresh = false}) async {
    if (!forceRefresh && (_isLoading || _lines.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lines = await _apiService.getLines(forceRefresh: forceRefresh);
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