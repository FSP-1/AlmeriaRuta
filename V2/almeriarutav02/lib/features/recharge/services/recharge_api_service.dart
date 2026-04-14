import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../models/recharge_profile_model.dart';

class RechargeApiService {
  final http.Client _client;

  RechargeApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<RechargeProfileModel?> fetchProfile({required String token}) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me/transport-profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        return RechargeProfileModel.fromJson(profile);
      }
      if (profile is Map) {
        return RechargeProfileModel.fromJson(profile.cast<String, dynamic>());
      }
      return null;
    }

    final message = data['error']?.toString() ?? 'No se pudo cargar el perfil de recarga';
    throw Exception(message);
  }

  Future<RechargeProfileModel?> fetchProfileOrNull({required String token}) async {
    try {
      return await fetchProfile(token: token);
    } catch (_) {
      return null;
    }
  }

  Future<RechargeProfileModel> saveProfile({
    required String token,
    required RechargeProfileModel profile,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.authApiBaseUrl}/auth/me/transport-profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile.toJson()),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseProfile = data['profile'];
      if (responseProfile is Map<String, dynamic>) {
        return RechargeProfileModel.fromJson(responseProfile);
      }
      if (responseProfile is Map) {
        return RechargeProfileModel.fromJson(responseProfile.cast<String, dynamic>());
      }
      throw Exception('Respuesta inválida del servidor');
    }

    final message = data['error']?.toString() ?? 'No se pudo guardar el perfil de recarga';
    throw Exception(message);
  }

  Future<void> updateSaldoBalance({
    required String token,
    required double saldoBalance,
  }) async {
    final currentProfile = await fetchProfileOrNull(token: token);
    final base = currentProfile ??
        const RechargeProfileModel(
          cardKey: 'saldo_virtual',
          cardLabel: 'Tarjeta Saldo Virtual',
          rechargeMode: 'saldo',
          ageGroup: 'general',
          travelCount: null,
          paymentMethod: 'Saldo',
          saldoBalance: 0,
          hasSaldoCard: true,
          cardState: 'active',
          configured: true,
        );

    await saveProfile(
      token: token,
      profile: RechargeProfileModel(
        cardKey: base.cardKey,
        cardLabel: base.cardLabel,
        rechargeMode: base.rechargeMode,
        ageGroup: base.ageGroup,
        travelCount: base.travelCount,
        paymentMethod: base.paymentMethod,
        saldoBalance: saldoBalance,
        hasSaldoCard: true,
        cardState: base.cardState,
        configured: true,
      ),
    );
  }
}
