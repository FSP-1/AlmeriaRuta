import 'package:flutter/material.dart';

import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/line_models.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
import '../models/notification_settings.dart';
import '../services/local_notification_service.dart';
import '../services/notification_storage.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationStorage _storage;
  final LocalNotificationService _localNotifications;
  final BusApiService _apiService;
  final FavoritesViewModel _favoritesViewModel;

  NotificationSettings _settings = const NotificationSettings.defaults();
  NotificationSettings _draft = const NotificationSettings.defaults();
  bool _loading = false;
  String? _error;

  List<LineModel>? _linesCache;

  NotificationSettings get settings => _settings;
  NotificationSettings get draft => _draft;
  bool get loading => _loading;
  String? get error => _error;

  bool get hasPendingChanges => _draft.toStorageString() != _settings.toStorageString();

  FavoritesViewModel get favorites => _favoritesViewModel;

  Future<List<LineModel>> getLines({bool forceRefresh = false}) async {
    if (!forceRefresh && _linesCache != null) return _linesCache!;
    final lines = await _apiService.getLines(forceRefresh: forceRefresh);
    _linesCache = lines;
    return lines;
  }

  Future<List<StopModel>> getLineStops(String lineId, {bool forceRefresh = false}) async {
    return _apiService.getLineStops(lineId, forceRefresh: forceRefresh);
  }

  Future<Map<String, int>> getStopArrivals(String stopId, {int limit = 5}) async {
    return _apiService.getStopArrivals(stopId, limit: limit);
  }

  NotificationsViewModel({
    NotificationStorage? storage,
    LocalNotificationService? localNotifications,
    BusApiService? apiService,
    required FavoritesViewModel favoritesViewModel,
  })  : _storage = storage ?? NotificationStorage(),
        _localNotifications = localNotifications ?? LocalNotificationService(),
        _apiService = apiService ?? BusApiService(),
        _favoritesViewModel = favoritesViewModel;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _favoritesViewModel.load();
      _settings = await _storage.load();
      _draft = _settings;

      // Apply schedules on load (best effort, in case the OS lost them).
      await _applySchedules(_settings);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setRechargeEnabled(bool enabled) {
    _draft = _draft.copyWith(recharge: _draft.recharge.copyWith(enabled: enabled));
    notifyListeners();
  }

  void setRechargeTime(TimeOfDay time) {
    _draft = _draft.copyWith(
      recharge: _draft.recharge.copyWith(hour: time.hour, minute: time.minute),
    );
    notifyListeners();
  }

  void setMonthlyExpiryDate(DateTime? date) {
    final iso = date == null ? null : _dateToIso(date);
    _draft = _draft.copyWith(
      recharge: _draft.recharge.copyWith(monthlyExpiryDateIso: iso),
    );
    notifyListeners();
  }

  void setArrivalEnabled(bool enabled) {
    _draft = _draft.copyWith(arrival: _draft.arrival.copyWith(enabled: enabled));
    notifyListeners();
  }

  void setArrivalLeadMinutes(int minutes) {
    _draft = _draft.copyWith(arrival: _draft.arrival.copyWith(leadMinutes: minutes));
    notifyListeners();
  }

  void setArrivalLine({required String id, required String name}) {
    _draft = _draft.copyWith(arrival: _draft.arrival.copyWith(lineId: id, lineName: name));
    notifyListeners();
  }

  void setArrivalStop({required String id, required String name}) {
    _draft = _draft.copyWith(
      arrival: _draft.arrival.copyWith(
        stopId: id,
        stopName: name,
        lineId: null,
        lineName: null,
      ),
    );
    notifyListeners();
  }

  void clearArrivalTarget() {
    _draft = _draft.copyWith(
      arrival: _draft.arrival.copyWith(stopId: null, stopName: null, lineId: null, lineName: null),
    );
    notifyListeners();
  }

  Future<void> acceptChanges() async {
    _error = null;
    notifyListeners();

    try {
      _settings = _draft;
      await _storage.save(_settings);
      await _applySchedules(_settings);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void discardChanges() {
    _draft = _settings;
    notifyListeners();
  }

  Future<void> _applySchedules(NotificationSettings s) async {
    // Ask for permissions only if any notification gets enabled.
    final anyEnabled = s.recharge.enabled || s.arrival.enabled;
    if (anyEnabled) {
      await _localNotifications.requestPermissionsIfNeeded();
    }

    if (s.recharge.enabled) {
      final scheduled = _computeMonthlyExpiryReminderTime(s);
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

    if (s.arrival.enabled) {
      try {
        await _scheduleArrivalAlert(s);
      } catch (e) {
        _error = e.toString();
        await _localNotifications.cancelArrivalAlert();
      }
    } else {
      await _localNotifications.cancelArrivalAlert();
    }
  }

  DateTime? _computeMonthlyExpiryReminderTime(NotificationSettings s) {
    final iso = s.recharge.monthlyExpiryDateIso;
    if (iso == null || iso.isEmpty) return null;

    final expiry = _tryParseIsoDate(iso);
    if (expiry == null) return null;

    final reminderDate = expiry.subtract(const Duration(days: 3));
    final scheduled = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      s.recharge.hour,
      s.recharge.minute,
    );

    if (!scheduled.isAfter(DateTime.now())) return null;
    return scheduled;
  }

  Future<void> _scheduleArrivalAlert(NotificationSettings s) async {
    final lineId = s.arrival.lineId;
    final lineName = s.arrival.lineName;
    final stopId = s.arrival.stopId;
    final stopName = s.arrival.stopName;
    final leadMinutes = s.arrival.leadMinutes;

    if (lineId == null || lineName == null || stopId == null || stopName == null) {
      await _localNotifications.cancelArrivalAlert();
      return;
    }

    final arrivals = await _apiService.getStopArrivals(stopId, limit: 5);
    final minutesToArrive = arrivals[lineId];
    if (minutesToArrive == null) {
      await _localNotifications.cancelArrivalAlert();
      return;
    }

    final scheduledInMinutes = minutesToArrive - leadMinutes;
    if (scheduledInMinutes <= 0) {
      // If the bus is already within the lead window, notify immediately.
      if (minutesToArrive > 0 && minutesToArrive <= leadMinutes) {
        await _localNotifications.showArrivalAlertNow(
          lineName: lineName,
          stopName: stopName,
          leadMinutes: leadMinutes,
        );
      } else {
        await _localNotifications.cancelArrivalAlert();
      }
      return;
    }

    final scheduledTime = DateTime.now().add(Duration(minutes: scheduledInMinutes));

    await _localNotifications.scheduleOneShotArrivalAlert(
      scheduledTime: scheduledTime,
      lineName: lineName,
      stopName: stopName,
      leadMinutes: leadMinutes,
    );
  }

  String _dateToIso(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
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
