import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/auth_validators.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterFormCard extends StatefulWidget {
  const RegisterFormCard({super.key});

  @override
  State<RegisterFormCard> createState() => _RegisterFormCardState();
}

class _RegisterFormCardState extends State<RegisterFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _recoveryPinController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _recoveryPinController.dispose();
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validateUsername,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  helperText: 'Mínimo 8 caracteres, con letras y números',
                ),
                validator: AuthValidators.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recoveryPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN de recuperación',
                  border: OutlineInputBorder(),
                  helperText: '4 dígitos para recuperar tu contraseña',
                  counterText: '',
                ),
                validator: AuthValidators.validateRecoveryPin,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final success = await vm.register(
                          _emailController.text.trim(),
                          _usernameController.text.trim(),
                          _passwordController.text,
                          _recoveryPinController.text.trim(),
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                child: vm.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear cuenta'),
              ),
              const SizedBox(height: 8),
              const Text(
                'La cuenta registrada habilita tarjeta saldo, recargas y compra de tickets para otros usuarios.',
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
