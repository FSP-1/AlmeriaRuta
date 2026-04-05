import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/notifications/models/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    test('defaults contain disabled recharge and arrival settings', () {
      const settings = NotificationSettings.defaults();

      expect(settings.recharge.enabled, isFalse);
      expect(settings.arrival.enabled, isFalse);
      expect(settings.arrival.leadMinutes, 5);
    });

    test('copyWith updates nested settings', () {
      const settings = NotificationSettings.defaults();
      final updated = settings.copyWith(
        recharge: settings.recharge.copyWith(enabled: true, hour: 9, minute: 30),
        arrival: settings.arrival.copyWith(enabled: true, lineId: 'L1', stopId: '100'),
      );

      expect(updated.recharge.enabled, isTrue);
      expect(updated.recharge.hour, 9);
      expect(updated.arrival.enabled, isTrue);
      expect(updated.arrival.lineId, 'L1');
      expect(updated.arrival.stopId, '100');
    });

    test('storage round trip preserves data', () {
      const settings = NotificationSettings(
        recharge: RechargeReminderSettings(
          enabled: true,
          monthlyExpiryDateIso: '2026-04-30',
          hour: 20,
          minute: 15,
        ),
        arrival: ArrivalAlertSettings(
          enabled: true,
          leadMinutes: 7,
          lineId: 'L1',
          lineName: 'L1',
          stopId: '100',
          stopName: 'Parada 1',
        ),
      );

      final restored = NotificationSettings.fromStorageString(settings.toStorageString());

      expect(restored.recharge.enabled, isTrue);
      expect(restored.recharge.monthlyExpiryDateIso, '2026-04-30');
      expect(restored.arrival.leadMinutes, 7);
      expect(restored.arrival.stopName, 'Parada 1');
    });
  });
}
