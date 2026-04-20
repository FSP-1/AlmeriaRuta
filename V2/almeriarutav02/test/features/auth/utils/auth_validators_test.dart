import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/auth/utils/auth_validators.dart';

void main() {
  group('AuthValidators.validateLoginIdentifier', () {
    test('returns error on empty string', () {
      expect(AuthValidators.validateLoginIdentifier(''), isNotNull);
    });

    test('returns error on null', () {
      expect(AuthValidators.validateLoginIdentifier(null), isNotNull);
    });

    test('returns error on whitespace only', () {
      expect(AuthValidators.validateLoginIdentifier('   '), isNotNull);
    });

    test('returns null for valid email', () {
      expect(AuthValidators.validateLoginIdentifier('user@almeria.com'), isNull);
    });

    test('returns null for valid username', () {
      expect(AuthValidators.validateLoginIdentifier('usuario123'), isNull);
    });
  });

  group('AuthValidators.validateEmail', () {
    test('returns error on empty', () {
      expect(AuthValidators.validateEmail(''), isNotNull);
    });

    test('returns error on null', () {
      expect(AuthValidators.validateEmail(null), isNotNull);
    });

    test('returns error on missing @', () {
      expect(AuthValidators.validateEmail('useralmeria.com'), isNotNull);
    });

    test('returns error on missing domain', () {
      expect(AuthValidators.validateEmail('user@'), isNotNull);
    });

    test('returns error on missing TLD', () {
      expect(AuthValidators.validateEmail('user@almeria'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(AuthValidators.validateEmail('user@almeria.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(AuthValidators.validateEmail('user@mail.almeria.es'), isNull);
    });
  });

  group('AuthValidators.validateUsername', () {
    test('returns error when shorter than 3 chars', () {
      expect(AuthValidators.validateUsername('ab'), isNotNull);
    });

    test('returns error when longer than 20 chars', () {
      expect(AuthValidators.validateUsername('a' * 21), isNotNull);
    });

    test('returns error on special characters', () {
      expect(AuthValidators.validateUsername('user@name!'), isNotNull);
    });

    test('returns null for exactly 3 chars', () {
      expect(AuthValidators.validateUsername('abc'), isNull);
    });

    test('returns null for exactly 20 chars', () {
      expect(AuthValidators.validateUsername('a' * 20), isNull);
    });

    test('returns null for username with spaces and underscores', () {
      expect(AuthValidators.validateUsername('Juan Garcia_01'), isNull);
    });

    test('returns null for username with accented chars', () {
      expect(AuthValidators.validateUsername('AlvaroN'), isNull);
    });
  });

  group('AuthValidators.validatePassword', () {
    test('returns error when shorter than 8 chars', () {
      expect(AuthValidators.validatePassword('abc1'), isNotNull);
    });

    test('returns error when no letters', () {
      expect(AuthValidators.validatePassword('12345678'), isNotNull);
    });

    test('returns error when no numbers', () {
      expect(AuthValidators.validatePassword('abcdefgh'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(AuthValidators.validatePassword('almeria1'), isNull);
    });

    test('returns null for password with special chars', () {
      expect(AuthValidators.validatePassword('Almer1a!'), isNull);
    });

    test('returns error on null', () {
      expect(AuthValidators.validatePassword(null), isNotNull);
    });
  });

  group('AuthValidators.validateRecoveryPin', () {
    test('returns error on empty', () {
      expect(AuthValidators.validateRecoveryPin(''), isNotNull);
    });

    test('returns error on null', () {
      expect(AuthValidators.validateRecoveryPin(null), isNotNull);
    });

    test('returns error on 3 digits', () {
      expect(AuthValidators.validateRecoveryPin('123'), isNotNull);
    });

    test('returns error on 5 digits', () {
      expect(AuthValidators.validateRecoveryPin('12345'), isNotNull);
    });

    test('returns error on letters', () {
      expect(AuthValidators.validateRecoveryPin('abcd'), isNotNull);
    });

    test('returns null for exactly 4 digits', () {
      expect(AuthValidators.validateRecoveryPin('1234'), isNull);
    });

    test('returns null for pin with leading zeros', () {
      expect(AuthValidators.validateRecoveryPin('0042'), isNull);
    });
  });

  group('AuthValidators.validateCurrentPassword', () {
    test('returns error on empty', () {
      expect(AuthValidators.validateCurrentPassword(''), isNotNull);
    });

    test('returns error on null', () {
      expect(AuthValidators.validateCurrentPassword(null), isNotNull);
    });

    test('returns null for any non-empty string', () {
      expect(AuthValidators.validateCurrentPassword('cualquier'), isNull);
    });
  });
}
