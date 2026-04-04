import '../models/notification_settings.dart';
import 'arrival_observer_service.dart';
import 'local_notification_service.dart';
import 'notification_storage.dart';

class NotificationSchedulerService {
  final NotificationStorage _storage;
  final LocalNotificationService _localNotifications;
  final ArrivalObserverService _arrivalObserver;

  NotificationSchedulerService({
    NotificationStorage? storage,
    LocalNotificationService? localNotifications,
    ArrivalObserverService? arrivalObserver,
  })  : _storage = storage ?? NotificationStorage(),
        _localNotifications = localNotifications ?? LocalNotificationService(),
        _arrivalObserver = arrivalObserver ?? ArrivalObserverService();

  Future<void> restoreFromStorage() async {
    final settings = await _storage.load();
    await applySchedules(settings);
  }

  Future<void> applySchedules(NotificationSettings settings) async {
    final anyEnabled = settings.recharge.enabled || settings.arrival.enabled;
    if (anyEnabled) {
      await _localNotifications.requestPermissionsIfNeeded();
    }

    if (settings.recharge.enabled) {
      final scheduled = _computeMonthlyExpiryReminderTime(settings);
      if (scheduled != null) {
        await _localNotifications.scheduleMonthlyCardExpiryReminder(
          scheduledTime: scheduled,
        );
      } else {
        await _localNotifications.cancelRechargeReminder();
      }
    } else {
      await _localNotifications.cancelRechargeReminder();
    }

    if (settings.arrival.enabled) {
      await _arrivalObserver.updateFromSettings(settings.arrival);
    } else {
      await _localNotifications.cancelArrivalAlert();
      await _arrivalObserver.updateFromSettings(settings.arrival);
    }
  }

  DateTime? _computeMonthlyExpiryReminderTime(NotificationSettings settings) {
    final iso = settings.recharge.monthlyExpiryDateIso;
    if (iso == null || iso.isEmpty) return null;

    final expiry = _tryParseIsoDate(iso);
    if (expiry == null) return null;

    final reminderDate = expiry.subtract(const Duration(days: 3));
    final scheduled = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      settings.recharge.hour,
      settings.recharge.minute,
    );

    if (!scheduled.isAfter(DateTime.now())) return null;
    return scheduled;
  }

  DateTime? _tryParseIsoDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
