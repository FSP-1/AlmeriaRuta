import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'widgets/auth_intro_card.dart';
import 'widgets/login_form_card.dart';
import 'widgets/register_form_card.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Acceso a AlmeriaRuta'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4B5563),
          bottom: const TabBar(
            labelColor: Color(0xFFB42318),
            unselectedLabelColor: Color(0xFF4B5563),
            tabs: [
              Tab(text: 'Entrar'),
              Tab(text: 'Crear cuenta'),
            ],
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: AuthIntroCard(),
            ),
            if (vm.error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.error!,
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                    ),
                    TextButton(
                      onPressed: vm.clearError,
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            const Expanded(
              child: TabBarView(
                children: [
                  LoginFormCard(),
                  RegisterFormCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}