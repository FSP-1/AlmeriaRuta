import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../models/app_user.dart';

class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<(String, AppUser)> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    return _parseAuthResponse(response);
  }

  Future<(String, AppUser)> register({
    required String email,
    required String username,
    required String password,
    required String recoveryPin,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
        'recoveryPin': recoveryPin,
      }),
    );

    return _parseAuthResponse(response);
  }

  Future<String> recoverPassword({
    required String email,
    required String recoveryPin,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/recover/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'recoveryPin': recoveryPin,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'No se pudo recuperar la contraseña');
    }
    return data['temporaryPassword']?.toString() ?? '';
  }

  Future<(String, AppUser)> guest() async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/guest'),
      headers: {'Content-Type': 'application/json'},
    );

    return _parseAuthResponse(response);
  }

  Future<AppUser> me(String token) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Sesion no valida');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  Future<(String, AppUser)> updateProfile({
    required String token,
    required String email,
    required String username,
  }) async {
    final response = await _client.patch(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'username': username,
      }),
    );

    return _parseAuthResponse(response);
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'No se pudo cambiar la contraseña');
    }
  }

  (String, AppUser) _parseAuthResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data['token']?.toString() ?? '';
      final user = AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
      return (token, user);
    }

    final message = data['error']?.toString() ?? 'Error de autenticacion';
    throw Exception(message);
  }
}
