import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:almeriarutav02/features/notifications/models/notification_settings.dart';
import 'package:almeriarutav02/features/notifications/services/notification_storage.dart';

void main() {
  group('NotificationStorage', () {
    late NotificationStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = NotificationStorage();
    });

    test('load returns defaults when no value exists', () async {
      final settings = await storage.load();

      expect(settings.recharge.enabled, isFalse);
      expect(settings.arrival.enabled, isFalse);
      expect(settings.arrival.leadMinutes, 5);
    });

    test('save and load roundtrip persists settings', () async {
      const settings = NotificationSettings(
        recharge: RechargeReminderSettings(
          enabled: true,
          monthlyExpiryDateIso: '2026-05-10',
          hour: 9,
          minute: 45,
        ),
        arrival: ArrivalAlertSettings(
          enabled: true,
          leadMinutes: 3,
          lineId: 'L1',
          lineName: 'L1',
          stopId: '100',
          stopName: 'Parada Centro',
        ),
      );

      await storage.save(settings);
      final loaded = await storage.load();

      expect(loaded.recharge.enabled, isTrue);
      expect(loaded.recharge.monthlyExpiryDateIso, '2026-05-10');
      expect(loaded.recharge.hour, 9);
      expect(loaded.recharge.minute, 45);
      expect(loaded.arrival.enabled, isTrue);
      expect(loaded.arrival.leadMinutes, 3);
      expect(loaded.arrival.lineId, 'L1');
      expect(loaded.arrival.stopId, '100');
    });

    test('load falls back to defaults for invalid raw payload', () async {
      SharedPreferences.setMockInitialValues({
        'notification_settings': '{invalid-json',
      });
      storage = NotificationStorage();

      final settings = await storage.load();

      expect(settings.recharge.enabled, isFalse);
      expect(settings.arrival.enabled, isFalse);
      expect(settings.arrival.lineId, isNull);
    });
  });
}
