import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:almeriarutav02/features/auth/services/auth_api_service.dart';
import 'package:almeriarutav02/features/auth/models/app_user.dart';

http.Response _jsonResponse(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}

const _validAuthBody = {
  'token': 'tok-abc',
  'user': {'id': 1, 'email': 'u@almeria.com', 'username': 'usuario', 'guest': false},
};

void main() {
  group('AuthApiService.login', () {
    test('returns token and user on 200', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse(_validAuthBody)),
      );

      final (token, user) = await svc.login(identifier: 'u@almeria.com', password: 'pass1234');

      expect(token, 'tok-abc');
      expect(user.email, 'u@almeria.com');
      expect(user.guest, isFalse);
    });

    test('throws on 401 with backend error message', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'error': 'Credenciales incorrectas'}, status: 401)),
      );

      expect(
        () => svc.login(identifier: 'bad', password: 'bad'),
        throwsA(predicate((e) => e.toString().contains('Credenciales incorrectas'))),
      );
    });

    test('throws on 500', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'error': 'Server error'}, status: 500)),
      );

      expect(() => svc.login(identifier: 'u', password: 'p'), throwsException);
    });
  });

  group('AuthApiService.register', () {
    test('returns token and user on 200', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse(_validAuthBody)),
      );

      final (token, user) = await svc.register(
        email: 'u@almeria.com',
        username: 'usuario',
        password: 'pass1234',
        recoveryPin: '1234',
      );

      expect(token, 'tok-abc');
      expect(user.username, 'usuario');
    });

    test('throws on 409 duplicate user', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'error': 'Usuario ya existe'}, status: 409)),
      );

      expect(
        () => svc.register(email: 'e@e.com', username: 'u', password: 'pass1234', recoveryPin: '0000'),
        throwsA(predicate((e) => e.toString().contains('Usuario ya existe'))),
      );
    });
  });

  group('AuthApiService.guest', () {
    test('returns guest token and user', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({
          'token': 'guest-tok',
          'user': {'id': null, 'email': null, 'username': 'Invitado-abc', 'guest': true},
        })),
      );

      final (token, user) = await svc.guest();

      expect(token, 'guest-tok');
      expect(user.guest, isTrue);
      expect(user.id, isNull);
    });
  });

  group('AuthApiService.me', () {
    test('returns AppUser on 200', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse(
          {'id': 1, 'email': 'u@almeria.com', 'username': 'usuario', 'guest': false},
        )),
      );

      final user = await svc.me('tok-abc');

      expect(user, isA<AppUser>());
      expect(user.email, 'u@almeria.com');
    });

    test('throws on non-200', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => http.Response('Unauthorized', 401)),
      );

      expect(() => svc.me('bad-token'), throwsException);
    });
  });

  group('AuthApiService.recoverPassword', () {
    test('returns temporaryPassword on success', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'success': true, 'temporaryPassword': 'ARtmp9'})),
      );

      final tmp = await svc.recoverPassword(email: 'u@almeria.com', recoveryPin: '1234');
      expect(tmp, 'ARtmp9');
    });

    test('throws on 404 user not found', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'error': 'Usuario no encontrado'}, status: 404)),
      );

      expect(
        () => svc.recoverPassword(email: 'x@x.com', recoveryPin: '0000'),
        throwsA(predicate((e) => e.toString().contains('Usuario no encontrado'))),
      );
    });
  });

  group('AuthApiService.updateProfile', () {
    test('returns new token and updated user on 200', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({
          'token': 'new-tok',
          'user': {'id': 1, 'email': 'new@almeria.com', 'username': 'nuevo', 'guest': false},
        })),
      );

      final (token, user) = await svc.updateProfile(
        token: 'old-tok',
        email: 'new@almeria.com',
        username: 'nuevo',
      );

      expect(token, 'new-tok');
      expect(user.email, 'new@almeria.com');
    });

    test('throws on 409 email already in use', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'error': 'El email ya está en uso'}, status: 409)),
      );

      expect(
        () => svc.updateProfile(token: 't', email: 'dup@dup.com', username: 'u'),
        throwsA(predicate((e) => e.toString().contains('El email ya está en uso'))),
      );
    });
  });

  group('AuthApiService.changePassword', () {
    test('completes without throwing on 200', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'success': true})),
      );

      await expectLater(
        svc.changePassword(token: 't', currentPassword: 'old1234', newPassword: 'new1234'),
        completes,
      );
    });

    test('throws on 401 wrong current password', () async {
      final svc = AuthApiService(
        client: MockClient((_) async => _jsonResponse({'error': 'Contraseña actual incorrecta'}, status: 401)),
      );

      expect(
        () => svc.changePassword(token: 't', currentPassword: 'wrong', newPassword: 'new1234'),
        throwsA(predicate((e) => e.toString().contains('Contraseña actual incorrecta'))),
      );
    });
  });
}
