import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/auth_validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../password_recovery_view.dart';

class LoginFormCard extends StatefulWidget {
  const LoginFormCard({super.key});

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email o usuario',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validateLoginIdentifier,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validatePassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final success = await vm.login(
                          _identifierController.text.trim(),
                          _passwordController.text,
                        );
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                child: vm.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: vm.loading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PasswordRecoveryView(),
                          ),
                        );
                      },
                child: const Text('Recuperar contraseña'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión con tu cuenta para gestionar tickets y saldo.',
                style: TextStyle(color: Color(0xFF4B5563)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
