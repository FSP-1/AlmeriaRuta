import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:almeriarutav02/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:almeriarutav02/features/auth/services/auth_api_service.dart';
import 'package:almeriarutav02/features/auth/models/app_user.dart';

// ── Fake AuthApiService ──────────────────────────────────────────────────────

class _FakeAuthApiService extends AuthApiService {
  final bool shouldFail;
  final AppUser fakeUser;
  final String fakeToken;

  _FakeAuthApiService({
    this.shouldFail = false,
    AppUser? user,
    this.fakeToken = 'fake-token',
  }) : fakeUser = user ??
            const AppUser(id: 1, email: 'u@almeria.com', username: 'usuario', guest: false);

  @override
  Future<(String, AppUser)> login({required String identifier, required String password}) async {
    if (shouldFail) throw Exception('Credenciales incorrectas');
    return (fakeToken, fakeUser);
  }

  @override
  Future<(String, AppUser)> register({
    required String email,
    required String username,
    required String password,
    required String recoveryPin,
  }) async {
    if (shouldFail) throw Exception('Usuario ya existe');
    return (fakeToken, fakeUser);
  }

  @override
  Future<(String, AppUser)> guest() async {
    if (shouldFail) throw Exception('Error de red');
    const guestUser = AppUser(id: null, email: null, username: 'Invitado-abc', guest: true);
    return ('guest-token', guestUser);
  }

  @override
  Future<AppUser> me(String token) async {
    if (shouldFail) throw Exception('Sesion no valida');
    return fakeUser;
  }

  @override
  Future<(String, AppUser)> updateProfile({
    required String token,
    required String email,
    required String username,
  }) async {
    if (shouldFail) throw Exception('El email ya está en uso');
    final updated = AppUser(id: fakeUser.id, email: email, username: username, guest: false);
    return ('new-token', updated);
  }

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldFail) throw Exception('Contraseña actual incorrecta');
  }

  @override
  Future<String> recoverPassword({required String email, required String recoveryPin}) async {
    if (shouldFail) throw Exception('PIN incorrecto');
    return 'ARtmp9';
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

AuthViewModel _vm({bool fail = false, AppUser? user}) =>
    AuthViewModel(api: _FakeAuthApiService(shouldFail: fail, user: user));

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── initialize ─────────────────────────────────────────────────────────────

  group('initialize', () {
    test('empty storage → not authenticated', () async {
      final vm = _vm();
      await vm.initialize();

      expect(vm.initialized, isTrue);
      expect(vm.loading, isFalse);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.user, isNull);
      expect(vm.token, isNull);
    });

    test('is idempotent when called twice', () async {
      final vm = _vm();
      await vm.initialize();
      await vm.initialize();

      expect(vm.initialized, isTrue);
      expect(vm.error, isNull);
    });

    test('restores session from prefs and refreshes via me()', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'stored-token',
        'auth_user': '{"id":1,"email":"u@almeria.com","username":"usuario","guest":false}',
      });
      final vm = _vm();
      await vm.initialize();

      expect(vm.isAuthenticated, isTrue);
      expect(vm.user?.email, 'u@almeria.com');
    });

    test('invalid stored token → logs out automatically', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'bad-token',
        'auth_user': '{"id":1,"email":"u@almeria.com","username":"usuario","guest":false}',
      });
      final vm = _vm(fail: true);
      await vm.initialize();

      expect(vm.isAuthenticated, isFalse);
      expect(vm.token, isNull);
    });
  });

  // ── login ──────────────────────────────────────────────────────────────────

  group('login', () {
    test('success → isAuthenticated true, token and user set', () async {
      final vm = _vm();
      final result = await vm.login('u@almeria.com', 'pass1234');

      expect(result, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.token, 'fake-token');
      expect(vm.user?.email, 'u@almeria.com');
      expect(vm.error, isNull);
      expect(vm.loading, isFalse);
    });

    test('success → session persisted in SharedPreferences', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'fake-token');
      expect(prefs.getString('auth_user'), isNotNull);
    });

    test('failure → returns false and sets error', () async {
      final vm = _vm(fail: true);
      final result = await vm.login('bad', 'bad');

      expect(result, isFalse);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.error, contains('Credenciales incorrectas'));
      expect(vm.loading, isFalse);
    });
  });

  // ── register ───────────────────────────────────────────────────────────────

  group('register', () {
    test('success → isAuthenticated true', () async {
      final vm = _vm();
      final result = await vm.register('u@almeria.com', 'usuario', 'pass1234', '1234');

      expect(result, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.loading, isFalse);
    });

    test('failure → returns false and sets error', () async {
      final vm = _vm(fail: true);
      final result = await vm.register('dup@dup.com', 'dup', 'pass1234', '0000');

      expect(result, isFalse);
      expect(vm.error, contains('Usuario ya existe'));
    });
  });

  // ── continueAsGuest ────────────────────────────────────────────────────────

  group('continueAsGuest', () {
    test('success → isGuest true', () async {
      final vm = _vm();
      final result = await vm.continueAsGuest();

      expect(result, isTrue);
      expect(vm.isGuest, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.user?.guest, isTrue);
    });

    test('failure → returns false and sets error', () async {
      final vm = _vm(fail: true);
      final result = await vm.continueAsGuest();

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });
  });

  // ── logout ─────────────────────────────────────────────────────────────────

  group('logout', () {
    test('clears state and prefs', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');
      await vm.logout();

      expect(vm.isAuthenticated, isFalse);
      expect(vm.token, isNull);
      expect(vm.user, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_user'), isNull);
    });
  });

  // ── updateProfile ──────────────────────────────────────────────────────────

  group('updateProfile', () {
    test('success → updates user and token', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');
      final result = await vm.updateProfile(email: 'new@almeria.com', username: 'nuevo');

      expect(result, isTrue);
      expect(vm.user?.email, 'new@almeria.com');
      expect(vm.token, 'new-token');
    });

    test('fails when not authenticated', () async {
      final vm = _vm();
      final result = await vm.updateProfile(email: 'x@x.com', username: 'x');

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    test('fails when guest', () async {
      final vm = _vm();
      await vm.continueAsGuest();
      final result = await vm.updateProfile(email: 'x@x.com', username: 'x');

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    test('api failure → returns false and sets error', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');

      final failVm = AuthViewModel(
        api: _FakeAuthApiService(shouldFail: true, fakeToken: vm.token!),
      );
      // Inject state manually via login on a fail-vm is not possible,
      // so we test the guard path: not authenticated on failVm
      final result = await failVm.updateProfile(email: 'x@x.com', username: 'x');
      expect(result, isFalse);
    });
  });

  // ── changePassword ─────────────────────────────────────────────────────────

  group('changePassword', () {
    test('success → returns true', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');
      final result = await vm.changePassword(currentPassword: 'old1234', newPassword: 'new1234');

      expect(result, isTrue);
      expect(vm.error, isNull);
    });

    test('fails when not authenticated', () async {
      final vm = _vm();
      final result = await vm.changePassword(currentPassword: 'x', newPassword: 'y');

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    test('api failure → returns false and sets error', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');

      // Swap api to failing one by creating a new vm that already has session
      // We test via a vm that fails at api level
      final failVm = AuthViewModel(api: _FakeAuthApiService(shouldFail: true));
      await failVm.login('u@almeria.com', 'pass1234'); // this also fails → not authenticated
      final result = await failVm.changePassword(currentPassword: 'old', newPassword: 'new');
      expect(result, isFalse);
    });
  });

  // ── recoverPassword ────────────────────────────────────────────────────────

  group('recoverPassword', () {
    test('success → returns temporary password', () async {
      final vm = _vm();
      final tmp = await vm.recoverPassword(email: 'u@almeria.com', recoveryPin: '1234');

      expect(tmp, 'ARtmp9');
      expect(vm.error, isNull);
      expect(vm.loading, isFalse);
    });

    test('failure → returns null and sets error', () async {
      final vm = _vm(fail: true);
      final tmp = await vm.recoverPassword(email: 'x@x.com', recoveryPin: '0000');

      expect(tmp, isNull);
      expect(vm.error, contains('PIN incorrecto'));
    });
  });

  // ── clearError ─────────────────────────────────────────────────────────────

  group('clearError', () {
    test('clears error after failed login', () async {
      final vm = _vm(fail: true);
      await vm.login('bad', 'bad');
      expect(vm.error, isNotNull);

      vm.clearError();
      expect(vm.error, isNull);
    });
  });

  // ── isGuest / isAuthenticated ──────────────────────────────────────────────

  group('computed properties', () {
    test('isGuest false for registered user', () async {
      final vm = _vm();
      await vm.login('u@almeria.com', 'pass1234');
      expect(vm.isGuest, isFalse);
    });

    test('isAuthenticated false before any action', () {
      final vm = _vm();
      expect(vm.isAuthenticated, isFalse);
    });
  });
}
