import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginIdentifier = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerUsername = TextEditingController();
  final _registerPassword = TextEditingController();

  @override
  void dispose() {
    _loginIdentifier.dispose();
    _loginPassword.dispose();
    _registerEmail.dispose();
    _registerUsername.dispose();
    _registerPassword.dispose();
    super.dispose();
  }

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acceso con reglas claras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Registrarte activa el uso de tarjeta bus, tarjeta saldo y la compra de tickets para otros usuarios.',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
            Expanded(
              child: TabBarView(
                children: [
                  _buildLogin(vm),
                  _buildRegister(vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogin(AuthViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _loginFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _loginIdentifier,
                decoration: const InputDecoration(
                  labelText: 'Email o usuario',
                  border: OutlineInputBorder(),
                ),
                validator: _validateLoginIdentifier,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _loginPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!(_loginFormKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final success = await vm.login(
                          _loginIdentifier.text.trim(),
                          _loginPassword.text,
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
                    : const Text('Entrar'),
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

  Widget _buildRegister(AuthViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _registerFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _registerEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registerUsername,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
                validator: _validateUsername,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registerPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  helperText: 'Mínimo 8 caracteres, con letras y números',
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!(_registerFormKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final success = await vm.register(
                          _registerEmail.text.trim(),
                          _registerUsername.text.trim(),
                          _registerPassword.text,
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

  String? _validateLoginIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Introduce email o usuario';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Introduce tu email';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Email no válido';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (text.length > 20) {
      return 'Máximo 20 caracteres';
    }
    final usernameRegex = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9_ ]+$');
    if (!usernameRegex.hasMatch(text)) {
      return 'Usa solo letras, números, espacios o _';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) {
      return 'Debe incluir letras';
    }
    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return 'Debe incluir números';
    }
    return null;
  }
}