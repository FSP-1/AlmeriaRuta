import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/auth/models/app_user.dart';

void main() {
  group('AppUser.fromJson', () {
    test('parses integer id and all fields correctly', () {
      final user = AppUser.fromJson({
        'id': 7,
        'email': 'test@almeria.com',
        'username': 'cliente',
        'guest': true,
        'isOperario': true,
      });

      expect(user.id, 7);
      expect(user.email, 'test@almeria.com');
      expect(user.username, 'cliente');
      expect(user.guest, isTrue);
      expect(user.isOperario, isTrue);
    });

    test('parses string id via int.tryParse', () {
      final user = AppUser.fromJson({'id': '42', 'email': null, 'username': 'u', 'guest': false});
      expect(user.id, 42);
    });

    test('null id stays null', () {
      final user = AppUser.fromJson({'id': null, 'email': null, 'username': 'u', 'guest': false});
      expect(user.id, isNull);
    });

    test('missing username defaults to "Usuario"', () {
      final user = AppUser.fromJson({'id': 1, 'email': 'a@b.com', 'guest': false});
      expect(user.username, 'Usuario');
    });

    test('null username defaults to "Usuario"', () {
      final user = AppUser.fromJson({'id': 1, 'email': 'a@b.com', 'username': null, 'guest': false});
      expect(user.username, 'Usuario');
    });

    test('missing guest defaults to false', () {
      final user = AppUser.fromJson({'id': 1, 'email': 'a@b.com', 'username': 'u'});
      expect(user.guest, isFalse);
    });

    test('guest true is preserved', () {
      final user = AppUser.fromJson({'id': null, 'email': null, 'username': 'Invitado-abc', 'guest': true});
      expect(user.guest, isTrue);
    });

    test('null email is preserved as null', () {
      final user = AppUser.fromJson({'id': 1, 'email': null, 'username': 'u', 'guest': false});
      expect(user.email, isNull);
    });
  });

  group('AppUser.toJson', () {
    test('exports all fields correctly', () {
      const user = AppUser(id: 3, email: 'user@example.com', username: 'user', guest: false);
      expect(user.toJson(), {
        'id': 3,
        'email': 'user@example.com',
        'username': 'user',
        'guest': false,
        'isOperario': false,
      });
    });

    test('exports null id and email for guest', () {
      const user = AppUser(id: null, email: null, username: 'Invitado-xyz', guest: true);
      final json = user.toJson();
      expect(json['id'], isNull);
      expect(json['email'], isNull);
      expect(json['guest'], isTrue);
      expect(json['isOperario'], isFalse);
    });

    test('roundtrip fromJson -> toJson is stable', () {
      final original = {
        'id': 5,
        'email': 'r@r.com',
        'username': 'ronda',
        'guest': false,
        'isOperario': false,
      };
      final user = AppUser.fromJson(original);
      expect(user.toJson(), original);
    });
  });
}
