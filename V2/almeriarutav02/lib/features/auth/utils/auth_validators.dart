class AuthValidators {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _usernameRegex = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9_ ]+$');

  static String? validateLoginIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Introduce email o usuario';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Introduce tu email';
    }
    if (!_emailRegex.hasMatch(text)) {
      return 'Email no válido';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (text.length > 20) {
      return 'Máximo 20 caracteres';
    }
    if (!_usernameRegex.hasMatch(text)) {
      return 'Usa solo letras, números, espacios o _';
    }
    return null;
  }

  static String? validatePassword(String? value) {
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

  static String? validateRecoveryPin(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Introduce un PIN de 4 dígitos';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(text)) {
      return 'El PIN debe tener exactamente 4 dígitos';
    }
    return null;
  }

  static String? validateCurrentPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Introduce la contraseña actual';
    }
    return null;
  }
}