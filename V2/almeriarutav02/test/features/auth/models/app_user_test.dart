import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/auth/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('fromJson accepts integer id and preserves fields', () {
      final user = AppUser.fromJson({
        'id': 7,
        'email': 'test@almeria.com',
        'username': 'cliente',
        'guest': true,
      });

      expect(user.id, 7);
      expect(user.email, 'test@almeria.com');
      expect(user.username, 'cliente');
      expect(user.guest, isTrue);
    });

    test('fromJson parses string id and applies default username', () {
      final user = AppUser.fromJson({
        'id': '42',
        'email': null,
      });

      expect(user.id, 42);
      expect(user.email, isNull);
      expect(user.username, 'Usuario');
      expect(user.guest, isFalse);
    });

    test('toJson exports expected map', () {
      const user = AppUser(
        id: 3,
        email: 'user@example.com',
        username: 'user',
        guest: false,
      );

      expect(user.toJson(), {
        'id': 3,
        'email': 'user@example.com',
        'username': 'user',
        'guest': false,
      });
    });
  });
}
