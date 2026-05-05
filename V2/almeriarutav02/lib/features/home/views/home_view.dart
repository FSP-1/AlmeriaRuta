import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/mobility_service_model.dart';
import '../../map/views/optimized_map_view.dart';
import '../../lines/views/lines_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../tickets/views/tickets_hub_view.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/coming_soon_dialog.dart';
import 'widgets/home_accessibility_info_card.dart';
import 'widgets/home_info_card.dart';
import 'widgets/home_section_card.dart';

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
                    child: HomeSectionCard(
                      service: service,
                      onTap: () => _handleServiceTap(context, service),
                      unreadNotificationsCount: 0,
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
                              child: HomeInfoCard(
                                service: entry.value,
                                onTap: () => _handleServiceTap(context, entry.value),
                              ),
                            ),
                          ]).expand((x) => x),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 4),
                  
                  // Tarjeta de notificaciones PRM desde ViewModel
                  HomeAccessibilityInfoCard(
                    service: viewModel.accessibilityService,
                    onTap: () =>
                        _handleServiceTap(context, viewModel.accessibilityService),
                  ),
                  
                  const SizedBox(height: 32),

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

  void _handleServiceTap(BuildContext context, MobilityServiceModel service) {
    switch (service.status) {
      case ServiceStatus.active:
        _navigateToService(context, service.id);
        break;
      case ServiceStatus.comingSoon:
      case ServiceStatus.information:
        showComingSoonDialog(context, service.title);
        break;
    }
  }

  void _navigateToService(BuildContext context, String serviceId) {
    switch (serviceId) {
      case 'lines':
        _navigateToLines(context);
        break;
      case 'tickets':
        _navigateToTicketsHub(context);
        break;
      case 'map':
        _navigateToMap(context);
        break;
      case 'notifications':
        _navigateToNotifications(context);
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

  void _navigateToTicketsHub(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TicketsHubView()),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }
}