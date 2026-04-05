import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/home/models/mobility_service_model.dart';
import 'package:almeriarutav02/features/home/viewmodels/home_viewmodel.dart';

void main() {
  group('HomeViewModel', () {
    test('exposes initial state', () {
      final vm = HomeViewModel();

      expect(vm.lines, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    test('contains expected core bus services', () {
      final vm = HomeViewModel();
      final ids = vm.busServices.map((s) => s.id).toList();

      expect(ids, containsAll(['lines', 'tickets', 'recharge', 'notifications', 'map']));
      expect(vm.busServices.where((s) => s.status == ServiceStatus.active), hasLength(5));
    });

    test('contains informational urban and accessibility services', () {
      final vm = HomeViewModel();

      expect(vm.urbanMobilityServices, hasLength(4));
      expect(vm.urbanMobilityServices.every((s) => s.status == ServiceStatus.comingSoon), isTrue);
      expect(vm.accessibilityService.status, ServiceStatus.information);
    });
  });
}
