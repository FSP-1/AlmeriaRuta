import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/auth_validators.dart';
import '../viewmodels/auth_viewmodel.dart';

class PasswordRecoveryView extends StatefulWidget {
  const PasswordRecoveryView({super.key});

  @override
  State<PasswordRecoveryView> createState() => _PasswordRecoveryViewState();
}

class _PasswordRecoveryViewState extends State<PasswordRecoveryView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: const Color(0xFFB42318),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Introduce tu email y tu PIN para recuperar tu contraseña.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                if (vm.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Gmail / Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: AuthValidators.validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'PIN de recuperación',
                    border: OutlineInputBorder(),
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

                          final temporaryPassword = await vm.recoverPassword(
                            email: _emailController.text.trim(),
                            recoveryPin: _pinController.text.trim(),
                          );
                          if (!context.mounted) return;
                          if (temporaryPassword != null && temporaryPassword.isNotEmpty) {
                            await showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Contraseña temporal'),
                                content: SelectableText(
                                  'Tu nueva contraseña temporal es:\n\n$temporaryPassword\n\nInicia sesión y cámbiala después.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          }
                        },
                  child: vm.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Recuperar contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
