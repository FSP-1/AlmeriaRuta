import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.username ?? 'Usuario'),
              subtitle: Text(user?.email ?? 'Cuenta activa'),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await context.read<AuthViewModel>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
