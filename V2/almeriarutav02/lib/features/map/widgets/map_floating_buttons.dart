import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MapFloatingButtons extends StatelessWidget {
  final bool hasActiveRoute;
  final VoidCallback onClearRoute;
  final VoidCallback onMyLocation;
  final VoidCallback onFavorites;

  const MapFloatingButtons({
    super.key,
    required this.hasActiveRoute,
    required this.onClearRoute,
    required this.onMyLocation,
    required this.onFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón de favoritos
          _buildFloatingButton(
            heroTag: "favorites",
            backgroundColor: Colors.amber,
            icon: Icons.star,
            iconColor: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            onPressed: onFavorites,
          ),
          const SizedBox(height: 12),
          // Botón cerrar ruta (si existe)
          if (hasActiveRoute) ...[
            _buildFloatingButton(
              heroTag: "clear_route",
              backgroundColor: Colors.white,
              icon: Icons.close,
              iconColor: Colors.red,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              onPressed: onClearRoute,
            ),
            const SizedBox(height: 12),
          ],
          // Botón mi ubicación
          _buildFloatingButton(
            heroTag: "my_location",
            backgroundColor: AppTheme.primaryRed,
            icon: Icons.my_location,
            iconColor: Colors.white,
            shadowColor: AppTheme.primaryRed.withValues(alpha: 0.3),
            shadowBlur: 12,
            onPressed: onMyLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required String heroTag,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required Color shadowColor,
    double shadowBlur = 8,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: backgroundColor,
        elevation: 0,
        onPressed: onPressed,
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
