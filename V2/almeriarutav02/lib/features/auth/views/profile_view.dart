import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../utils/auth_validators.dart';
import '../viewmodels/auth_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isEditingProfile = false;

  static const List<IconData> _availableAvatars = [
    Icons.person,
    Icons.person_outline,
    Icons.face,
    Icons.sentiment_satisfied,
    Icons.account_circle,
    Icons.emoji_people,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AuthViewModel>();
      _emailController.text = vm.user?.email ?? '';
      _usernameController.text = vm.user?.username ?? '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de usuario'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null || vm.isGuest)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Inicia sesión para editar tu perfil'),
              ),
            )
          else ...[
            _buildAvatarCard(vm),
            const SizedBox(height: 16),
            _buildProfileCard(vm),
            const SizedBox(height: 16),
            _buildPasswordCard(vm),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarCard(AuthViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Icono de perfil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAvatars
                  .map(
                    (icon) => ChoiceChip(
                      label: Icon(icon),
                      selected: vm.avatarIcon.codePoint == icon.codePoint,
                      onSelected: (_) => vm.setAvatarIcon(icon),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos personales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                enabled: _isEditingProfile,
                readOnly: !_isEditingProfile,
                decoration: const InputDecoration(
                  labelText: 'Gmail / Email',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                enabled: _isEditingProfile,
                readOnly: !_isEditingProfile,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validateUsername,
              ),
              const SizedBox(height: 12),
              if (!_isEditingProfile)
                ElevatedButton.icon(
                  onPressed: vm.loading
                      ? null
                      : () {
                          setState(() {
                            _isEditingProfile = true;
                          });
                        },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar datos'),
                )
              else
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: vm.loading
                          ? null
                          : () {
                              setState(() {
                                _isEditingProfile = false;
                                _emailController.text = vm.user?.email ?? '';
                                _usernameController.text = vm.user?.username ?? '';
                              });
                            },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: vm.loading
                          ? null
                          : () async {
                              if (!(_profileFormKey.currentState?.validate() ?? false)) {
                                return;
                              }

                              final ok = await vm.updateProfile(
                                email: _emailController.text.trim().toLowerCase(),
                                username: _usernameController.text.trim(),
                              );
                              if (!mounted) return;
                              if (ok) {
                                setState(() {
                                  _isEditingProfile = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Perfil actualizado')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(vm.error ?? 'No se pudo actualizar el perfil'),
                                  ),
                                );
                                vm.clearError();
                              }
                            },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(AuthViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar contraseña',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validateCurrentPassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repetir nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!(_passwordFormKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        final ok = await vm.changePassword(
                          currentPassword: _currentPasswordController.text,
                          newPassword: _newPasswordController.text,
                        );
                        if (!mounted) return;
                        if (ok) {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contraseña actualizada')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'No se pudo actualizar la contraseña'),
                            ),
                          );
                          vm.clearError();
                        }
                      },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}