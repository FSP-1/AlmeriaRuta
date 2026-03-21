import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/mobility_service_model.dart';
import '../../map/views/optimized_map_view.dart';
import '../../tickets/views/buy_ticket_view.dart';
import '../../recharge/views/recharge_view.dart';
import '../../lines/views/lines_view.dart';
import '../../../core/theme/app_theme.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadLines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlmeriaRuta'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundRed,
              Colors.white,
            ],
          ),
        ),
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          size: 80,
                          color: AppTheme.primaryRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Movilidad Municipal de Almería',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.darkRed,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transporte, estacionamiento, bicicletas y mucho más',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.darkRed.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nuevo: Modo turistico en el mapa para ver monumentos, museos y zonas populares.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Título sección principal
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '🚌 Servicios de Autobús',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkRed,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Servicios de autobús desde ViewModel
                  ...viewModel.busServices.map((service) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSectionCard(
                      context,
                      service: service,
                      onTap: () => _handleServiceTap(context, service),
                    ),
                  )),
                  
                  const SizedBox(height: 32),
                  
                  // Título sección movilidad urbana
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '🏙️ Otros Servicios de Movilidad',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkRed,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Servicios informativos - Próximamente funcionales',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Grid de servicios informativos desde ViewModel
                  ...List.generate((viewModel.urbanMobilityServices.length / 2).ceil(), (rowIndex) {
                    final startIndex = rowIndex * 2;
                    final endIndex = (startIndex + 2).clamp(0, viewModel.urbanMobilityServices.length);
                    final rowServices = viewModel.urbanMobilityServices.sublist(startIndex, endIndex);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ...rowServices.asMap().entries.map((entry) => [
                            if (entry.key > 0) const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                context,
                                service: entry.value,
                              ),
                            ),
                          ]).expand((x) => x),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 4),
                  
                  // Tarjeta de notificaciones PRM desde ViewModel
                  _buildInfoNotificationCard(
                    context,
                    service: viewModel.accessibilityService,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Información adicional
                  if (!viewModel.isLoading && viewModel.error == null)
                    
                  
                  // Error state
                  if (viewModel.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 8),
                          Text('Error: ${viewModel.error}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => viewModel.loadLines(forceRefresh: true),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required MobilityServiceModel service,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service.icon,
                  size: 32,
                  color: service.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkRed,
                      ),
                    ),
                    if (service.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: service.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required MobilityServiceModel service,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleServiceTap(context, service),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.icon,
                  size: 32,
                  color: service.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Próximamente',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoNotificationCard(
    BuildContext context, {
    required MobilityServiceModel service,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleServiceTap(context, service),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  service.icon,
                  size: 28,
                  color: service.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkRed,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Info',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.primaryRed.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  size: 48,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Próximamente',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Esta funcionalidad estará disponible en futuras versiones de AlmeriaRuta.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Por ahora, nos enfocamos en ofrecerte el mejor servicio de información de autobuses urbanos.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleServiceTap(BuildContext context, MobilityServiceModel service) {
    switch (service.status) {
      case ServiceStatus.active:
        _navigateToService(context, service.id);
        break;
      case ServiceStatus.comingSoon:
      case ServiceStatus.information:
        _showComingSoonDialog(context, service.title);
        break;
    }
  }

  void _navigateToService(BuildContext context, String serviceId) {
    switch (serviceId) {
      case 'lines':
        _navigateToLines(context);
        break;
      case 'tickets':
        _navigateToTickets(context);
        break;
      case 'recharge':
        _navigateToRecharge(context);
        break;
      case 'map':
        _navigateToMap(context);
        break;
      default:
        break;
    }
  }

  void _navigateToLines(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LinesView()),
    );
  }

  void _navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OptimizedMapView()),
    );
  }

  void _navigateToTickets(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BuyTicketView()),
    );
  }

  void _navigateToRecharge(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RechargeView()),
    );
  }
}