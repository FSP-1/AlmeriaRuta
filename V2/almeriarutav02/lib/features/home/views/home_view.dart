import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../map/views/optimized_map_view.dart';
import '../../tickets/views/buy_ticket_view.dart';
import '../../recharge/views/recharge_view.dart';
import 'lines_view.dart';
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
                          'Transporte Público de Almería',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.darkRed,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Consulta horarios, rutas y paradas en tiempo real',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.darkRed.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección Líneas
                  _buildSectionCard(
                    context,
                    icon: Icons.route,
                    title: 'Líneas de Autobús',
                    subtitle: viewModel.isLoading 
                        ? 'Cargando...' 
                        : '${viewModel.lines.length} líneas disponibles',
                    description: 'Consulta todas las líneas urbanas, horarios y paradas',
                    onTap: () => _navigateToLines(context),
                    color: AppTheme.primaryRed,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sección Tickets
                  _buildSectionCard(
                    context,
                    icon: Icons.credit_card,
                    title: 'Comprar Tickets',
                    subtitle: 'Tickets y tarjeta virtual',
                    description: 'Compra tickets individuales, múltiples o tarjeta recargable',
                    onTap: () => _navigateToTickets(context),
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sección Recargar
                  _buildSectionCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'Recargar Tarjetas',
                    subtitle: 'Gestiona tus títulos de transporte',
                    description: 'Recarga bonobús, tarjetas mensuales y títulos especiales',
                    onTap: () => _navigateToRecharge(context),
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sección Mapa
                  _buildSectionCard(
                    context,
                    icon: Icons.map,
                    title: 'Mapa Interactivo',
                    subtitle: 'Visualiza paradas en tiempo real',
                    description: 'Encuentra paradas cercanas con GPS y filtros por zona',
                    onTap: () => _navigateToMap(context),
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Información adicional
                  if (!viewModel.isLoading && viewModel.error == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.darkRed,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Datos oficiales de ALSA',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Información actualizada del transporte público de Almería',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  
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
                            onPressed: () => viewModel.loadLines(),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
    required Color color,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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