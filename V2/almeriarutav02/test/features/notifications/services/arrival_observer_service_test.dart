import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/notifications/models/notification_settings.dart';
import 'package:almeriarutav02/features/notifications/services/arrival_observer_service.dart';
import 'package:almeriarutav02/features/notifications/services/local_notification_service.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';

void main() {
  group('ArrivalObserverService', () {
    test('disabled settings cancel pending arrival alert', () async {
      final api = _FakeBusApiService();
      final notifications = _FakeLocalNotificationService();
      final service = ArrivalObserverService.testing(
        apiService: api,
        localNotifications: notifications,
      );

      await service.updateFromSettings(
        const ArrivalAlertSettings.defaults(),
      );

      expect(notifications.cancelArrivalCount, 1);
      expect(notifications.requestPermissionsCount, 0);
      service.stopObserving();
    });

    test('minutes above threshold schedule one-shot alert', () async {
      final api = _FakeBusApiService(arrivalsByLine: {'L1': 12});
      final notifications = _FakeLocalNotificationService();
      final service = ArrivalObserverService.testing(
        apiService: api,
        localNotifications: notifications,
      );

      await service.updateFromSettings(
        const ArrivalAlertSettings(
          enabled: true,
          leadMinutes: 5,
          lineId: 'L1',
          lineName: 'L1',
          stopId: '100',
          stopName: 'Parada Centro',
        ),
      );

      expect(notifications.requestPermissionsCount, 1);
      expect(api.lastStopId, '100');
      expect(notifications.scheduledCount, 1);
      expect(notifications.immediateCount, 0);
      service.stopObserving();
    });

    test('minutes under threshold trigger immediate alert once', () async {
      final api = _FakeBusApiService(arrivalsByLine: {'L1': 3});
      final notifications = _FakeLocalNotificationService();
      final service = ArrivalObserverService.testing(
        apiService: api,
        localNotifications: notifications,
      );

      const settings = ArrivalAlertSettings(
        enabled: true,
        leadMinutes: 5,
        lineId: 'L1',
        lineName: 'L1',
        stopId: '100',
        stopName: 'Parada Centro',
      );

      await service.updateFromSettings(settings);
      await service.updateFromSettings(settings);

      expect(notifications.immediateCount, 2);
      expect(notifications.scheduledCount, 0);
      service.stopObserving();
    });
  });
}

class _FakeBusApiService extends BusApiService {
  _FakeBusApiService({Map<String, int>? arrivalsByLine})
      : _arrivalsByLine = arrivalsByLine ?? <String, int>{};

  final Map<String, int> _arrivalsByLine;
  String? lastStopId;

  @override
  Future<Map<String, int>> getStopArrivals(String stopId, {int limit = 3}) async {
    lastStopId = stopId;
    return _arrivalsByLine;
  }
}

class _FakeLocalNotificationService extends LocalNotificationService {
  int cancelArrivalCount = 0;
  int requestPermissionsCount = 0;
  int scheduledCount = 0;
  int immediateCount = 0;

  @override
  Future<bool> requestPermissionsIfNeeded() async {
    requestPermissionsCount++;
    return true;
  }

  @override
  Future<void> cancelArrivalAlert() async {
    cancelArrivalCount++;
  }

  @override
  Future<void> scheduleOneShotArrivalAlert({
    required DateTime scheduledTime,
    String? lineName,
    required String stopName,
    required int leadMinutes,
  }) async {
    scheduledCount++;
  }

  @override
  Future<void> showArrivalAlertNow({
    String? lineName,
    required String stopName,
    required int leadMinutes,
  }) async {
    immediateCount++;
  }
}
