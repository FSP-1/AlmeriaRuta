import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/auth_screen.dart';
import '../../auth/views/profile_view.dart';
import '../../home/views/home_view.dart';
import '../../lines/views/lines_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../tickets/views/tickets_hub_view.dart';

class MapSimpleMenuOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const MapSimpleMenuOverlay({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.86 > 360
        ? 360.0
        : MediaQuery.of(context).size.width * 0.86;

    return Stack(
      children: [
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black54),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          top: 0,
          bottom: 0,
          right: isOpen ? 0 : -panelWidth,
          width: panelWidth,
          child: Material(
            color: const Color(0xFFF8FAFC),
            elevation: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: SafeArea(
              top: false,
              child: Consumer<AuthViewModel>(
                builder: (context, auth, _) {
                  return ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 10),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Menú',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: const Color(0xFF64748B),
                              onPressed: onClose,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.home_outlined,
                        color: const Color(0xFF0EA5E9),
                        title: 'Menú completo',
                        subtitle: 'Abrir menú principal completo',
                        onTap: () {
                          onClose();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeView()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.route_outlined,
                        color: const Color(0xFFDC2626),
                        title: 'Líneas de autobús',
                        onTap: () {
                          onClose();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LinesView()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.confirmation_number_outlined,
                        color: const Color(0xFF16A34A),
                        title: 'Billetes y tarjeta',
                        onTap: () {
                          onClose();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TicketsHubView()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.notifications_active_outlined,
                        color: const Color(0xFF7C3AED),
                        title: 'Notificaciones',
                        onTap: () {
                          onClose();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsView()),
                          );
                        },
                      ),
                      if (auth.isAuthenticated)
                        _buildMenuItem(
                          context: context,
                          icon: Icons.person_outline,
                          color: const Color(0xFF0F766E),
                          title: 'Perfil',
                          subtitle: 'Ver perfil de usuario',
                          onTap: () {
                            onClose();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileView()),
                            );
                          },
                        ),
                      _buildMenuItem(
                        context: context,
                        icon: auth.isAuthenticated ? Icons.logout : Icons.login,
                        color: const Color(0xFFB42318),
                        title: auth.isAuthenticated ? 'Cerrar sesión' : 'Iniciar sesión',
                        subtitle: auth.isAuthenticated
                            ? 'Cerrar sesión actual'
                            : 'Acceder con tu cuenta',
                        onTap: () async {
                          onClose();

                          if (!auth.isAuthenticated) {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                            return;
                          }

                          final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Cerrar sesión'),
                                  content: const Text(
                                    '¿Seguro que quieres cerrar tu sesión actual?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Salir'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (!context.mounted || !shouldLogout) {
                            return;
                          }

                          await auth.logout();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sesión cerrada')),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}