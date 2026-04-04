import 'package:flutter/material.dart';

import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/line_models.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
import '../models/notification_settings.dart';
import '../models/user_notification.dart';
import '../services/backend_notifications_api_service.dart';
import '../services/notification_scheduler_service.dart';
import '../services/notification_storage.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationStorage _storage;
  final BackendNotificationsApiService _backendNotifications;
  final BusApiService _apiService;
  final FavoritesViewModel _favoritesViewModel;
  final String? _token;
  final NotificationSchedulerService _notificationScheduler;

  NotificationSettings _settings = const NotificationSettings.defaults();
  NotificationSettings _draft = const NotificationSettings.defaults();
  bool _loading = false;
  String? _error;
  List<UserNotification> _remoteNotifications = [];

  List<LineModel>? _linesCache;

  NotificationSettings get settings => _settings;
  NotificationSettings get draft => _draft;
  bool get loading => _loading;
  String? get error => _error;
  List<UserNotification> get remoteNotifications => _remoteNotifications;

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
    BackendNotificationsApiService? backendNotifications,
    BusApiService? apiService,
    NotificationSchedulerService? notificationScheduler,
    required FavoritesViewModel favoritesViewModel,
    String? token,
  })  : _storage = storage ?? NotificationStorage(),
        _backendNotifications = backendNotifications ?? BackendNotificationsApiService(),
        _apiService = apiService ?? BusApiService(),
      _notificationScheduler = notificationScheduler ?? NotificationSchedulerService(),
        _favoritesViewModel = favoritesViewModel,
        _token = token;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _favoritesViewModel.load();
      _settings = await _storage.load();
      _draft = _settings;
      await _loadRemoteNotifications();

      // Apply schedules on load (best effort, in case the OS lost them).
      await _notificationScheduler.applySchedules(_settings);
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
      await _notificationScheduler.applySchedules(_settings);
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

  Future<void> refreshRemoteNotifications() async {
    try {
      await _loadRemoteNotifications(force: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markRemoteNotificationAsRead(int notificationId) async {
    final token = _token;
    if (token == null) return;
    try {
      await _backendNotifications.markAsRead(token: token, notificationId: notificationId);
    } catch (_) {
      // Idempotent behavior on client: if backend says not found, just refresh list.
    }
    await _loadRemoteNotifications(force: true);
  }

  Future<void> deleteRemoteNotification(int notificationId) async {
    final token = _token;
    if (token == null) return;
    try {
      await _backendNotifications.deleteNotification(token: token, notificationId: notificationId);
    } catch (_) {
      // If it was already removed, keep UI consistent by reloading anyway.
    }
    await _loadRemoteNotifications(force: true);
  }

  Future<void> _loadRemoteNotifications({bool force = false}) async {
    final token = _token;
    if (token == null) {
      _remoteNotifications = [];
      notifyListeners();
      return;
    }

    _remoteNotifications = await _backendNotifications.fetchNotifications(token: token, unreadOnly: !force ? false : false);
    notifyListeners();
  }

  String _dateToIso(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

}
