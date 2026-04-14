import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:almeriarutav02/features/recharge/models/recharge_profile_model.dart';
import 'package:almeriarutav02/features/recharge/services/recharge_api_service.dart';

void main() {
  group('RechargeApiService', () {
    test('fetchProfile returns parsed profile on 2xx', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer token-1');
        return http.Response(
          jsonEncode({
            'profile': {
              'cardKey': 'mensual_ordinaria',
              'cardLabel': 'Mensual Ordinaria',
              'rechargeMode': 'mensual',
              'ageGroup': 'general',
              'travelCount': null,
              'paymentMethod': 'Saldo',
              'saldoBalance': 0.0,
              'hasSaldoCard': false,
              'cardState': 'active',
              'configured': false,
            },
          }),
          200,
        );
      });

      final service = RechargeApiService(client: client);
      final profile = await service.fetchProfile(token: 'token-1');

      expect(profile, isNotNull);
      expect(profile!.cardKey, 'mensual_ordinaria');
      expect(profile.paymentMethod, 'Saldo');
      expect(profile.hasSaldoCard, isFalse);
    });

    test('fetchProfile throws backend error on non-2xx', () async {
      final client = MockClient((request) async {
        return http.Response('{"error":"Token expirado"}', 401);
      });

      final service = RechargeApiService(client: client);

      expect(
        () => service.fetchProfile(token: 'token-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Token expirado'),
          ),
        ),
      );
    });

    test('saveProfile sends payload and returns parsed profile on 2xx', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer token-2');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['cardKey'], 'bonobus_universidad');
        expect(body['paymentMethod'], 'Visa');

        return http.Response(
          jsonEncode({
            'profile': {
              'cardKey': body['cardKey'],
              'cardLabel': body['cardLabel'],
              'rechargeMode': body['rechargeMode'],
              'ageGroup': body['ageGroup'],
              'travelCount': body['travelCount'],
              'paymentMethod': body['paymentMethod'],
              'saldoBalance': body['saldoBalance'],
              'hasSaldoCard': body['hasSaldoCard'],
              'cardState': body['cardState'],
              'configured': true,
            },
          }),
          200,
        );
      });

      final service = RechargeApiService(client: client);
      final profile = await service.saveProfile(
        token: 'token-2',
        profile: const RechargeProfileModel(
          cardKey: 'bonobus_universidad',
          cardLabel: 'Bonobús Universidad',
          rechargeMode: 'bonobus',
          ageGroup: 'estudiante',
          travelCount: 10,
          paymentMethod: 'Visa',
          saldoBalance: 12.5,
          hasSaldoCard: true,
          cardState: 'active',
          configured: true,
        ),
      );

      expect(profile.cardKey, 'bonobus_universidad');
      expect(profile.paymentMethod, 'Visa');
      expect(profile.travelCount, 10);
      expect(profile.saldoBalance, 12.5);
      expect(profile.hasSaldoCard, isTrue);
    });

    test('saveProfile throws fallback message when backend omits error', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"fail"}', 500);
      });

      final service = RechargeApiService(client: client);

      expect(
        () => service.saveProfile(
          token: 'token-2',
          profile: const RechargeProfileModel(
            cardKey: 'saldo_virtual',
            cardLabel: 'Tarjeta Saldo Virtual',
            rechargeMode: 'saldo',
            ageGroup: 'general',
            travelCount: null,
            paymentMethod: 'Saldo',
            saldoBalance: 0,
            hasSaldoCard: false,
            cardState: 'active',
            configured: true,
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No se pudo guardar el perfil de recarga'),
          ),
        ),
      );
    });
  });
}
