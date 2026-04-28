import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MapTutorialDialog extends StatelessWidget {
  final bool isFirstTime;
  final VoidCallback onComplete;

  const MapTutorialDialog({
    super.key,
    required this.isFirstTime,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFFFF7F7),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFirstTime ? Icons.waving_hand : Icons.help_outline,
                    color: AppTheme.primaryRed,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFirstTime ? '¡Bienvenido!' : 'Ayuda',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      const Text(
                        'Guía rápida del mapa',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Contenido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryRed.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppTheme.primaryRed, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isFirstTime
                          ? 'Por defecto se muestran paradas cercanas a tu ubicación (800m).\nDesde el menú de capas puedes activar bus, turismo y zonas.'
                          : 'La vista inicial muestra paradas cercanas a tu ubicación (800m).',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A202C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Características
            _buildHelpItem(
              icon: Icons.near_me,
              iconColor: AppTheme.primaryRed,
              title: 'Menú de capas',
              description: 'Abre el menú principal para decidir qué capas ves: bus, turismo y zonas.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.directions_bus,
              iconColor: AppTheme.primaryRed,
              title: 'Paradas de bus',
              description: 'Dentro del menú puedes elegir cercanas, todas, favoritas o una línea concreta.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.travel_explore,
              iconColor: Colors.blue,
              title: 'Turismo',
              description: 'Activa o desactiva los puntos turísticos y elige categorías como playas, museos o parques.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.map,
              iconColor: Colors.green,
              title: 'Zonas',
              description: 'Selecciona una zona geográfica para acotar lo que ves en el mapa.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.search,
              iconColor: AppTheme.primaryRed,
              title: 'Buscar ubicaciones',
              description: 'Toca el icono de búsqueda para buscar direcciones',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.star,
              iconColor: Colors.amber,
              title: 'Gestionar favoritos',
              description: isFirstTime
                  ? 'Toca el botón amarillo del mapa para ver tus favoritos.'
                  : 'Ve a "Líneas" para marcar líneas favoritas',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.location_on,
              iconColor: Colors.purple,
              title: 'Ver paradas',
              description: 'Toca cualquier parada en el mapa para ver detalles',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.directions,
              iconColor: Colors.blue,
              title: 'Cómo llegar',
              description: 'Desde los detalles de una parada, puedes ver la ruta',
            ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botón
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isFirstTime ? '¡Empezar!' : 'Entendido',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF2D3748),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
