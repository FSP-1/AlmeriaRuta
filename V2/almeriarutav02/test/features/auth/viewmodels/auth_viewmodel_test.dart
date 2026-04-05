import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:almeriarutav02/features/auth/viewmodels/auth_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthViewModel', () {
    test('initialize with empty storage sets initialized state without auth', () async {
      SharedPreferences.setMockInitialValues({});
      final vm = AuthViewModel();

      await vm.initialize();

      expect(vm.initialized, isTrue);
      expect(vm.loading, isFalse);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.token, isNull);
      expect(vm.user, isNull);
    });

    test('initialize is idempotent when called twice', () async {
      SharedPreferences.setMockInitialValues({});
      final vm = AuthViewModel();

      await vm.initialize();
      await vm.initialize();

      expect(vm.initialized, isTrue);
      expect(vm.loading, isFalse);
      expect(vm.error, isNull);
    });

    test('logout clears persisted session keys', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token-1',
        'auth_user': '{"id":1,"email":"u@a.com","username":"u","guest":false}',
      });
      final vm = AuthViewModel();

      await vm.logout();
      final prefs = await SharedPreferences.getInstance();

      expect(vm.isAuthenticated, isFalse);
      expect(vm.token, isNull);
      expect(vm.user, isNull);
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_user'), isNull);
    });

    test('clearError leaves error as null in clean state', () {
      final vm = AuthViewModel();

      vm.clearError();

      expect(vm.error, isNull);
    });
  });
}
