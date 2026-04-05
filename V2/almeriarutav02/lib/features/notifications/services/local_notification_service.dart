import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static const int rechargeNotificationId = 1001;
  static const int arrivalNotificationId = 2001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {
      // Fallback to tz.local.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings: initSettings);

    _initialized = true;
  }

  Future<bool> requestPermissionsIfNeeded() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> cancelRechargeReminder() async {
    await initialize();
    await _plugin.cancel(id: rechargeNotificationId);
  }

  Future<void> cancelArrivalAlert() async {
    await initialize();
    await _plugin.cancel(id: arrivalNotificationId);
  }

  Future<void> scheduleMonthlyCardExpiryReminder({
    required DateTime scheduledTime,
  }) async {
    await initialize();

    if (!scheduledTime.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: rechargeNotificationId,
      scheduledDate: _toTZ(scheduledTime),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'recharge_reminders',
          'Recordatorios de recarga',
          channelDescription: 'Recordatorios para recargar tarjetas',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Recarga pendiente',
      body: 'Tu tarjeta mensual caduca pronto.',
    );
  }

  Future<void> scheduleOneShotArrivalAlert({
    required DateTime scheduledTime,
    String? lineName,
    required String stopName,
    required int leadMinutes,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (!scheduledTime.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id: arrivalNotificationId,
      scheduledDate: _toTZ(scheduledTime),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'arrival_alerts',
          'Avisos de llegada',
          channelDescription: 'Avisos cuando falten X minutos para llegar a una parada',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: (lineName == null || lineName.isEmpty) ? 'Bus en $leadMinutes min' : 'Bus $lineName en $leadMinutes min',
      body: 'Parada: $stopName',
    );
  }

  Future<void> showArrivalAlertNow({
    String? lineName,
    required String stopName,
    required int leadMinutes,
  }) async {
    await initialize();

    await _plugin.show(
      id: arrivalNotificationId,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'arrival_alerts',
          'Avisos de llegada',
          channelDescription: 'Avisos cuando falten X minutos para llegar a una parada',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      title: (lineName == null || lineName.isEmpty) ? 'Bus en $leadMinutes min' : 'Bus $lineName en $leadMinutes min',
      body: 'Parada: $stopName',
    );
  }

  tz.TZDateTime _toTZ(DateTime dt) => tz.TZDateTime.from(dt, tz.local);
}
