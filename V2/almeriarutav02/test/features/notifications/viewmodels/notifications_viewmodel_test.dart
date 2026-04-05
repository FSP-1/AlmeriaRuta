
import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/map/viewmodels/favorites_viewmodel.dart';
import 'package:almeriarutav02/features/notifications/models/notification_settings.dart';
import 'package:almeriarutav02/features/notifications/models/user_notification.dart';
import 'package:almeriarutav02/features/notifications/services/backend_notifications_api_service.dart';
import 'package:almeriarutav02/features/notifications/services/notification_scheduler_service.dart';
import 'package:almeriarutav02/features/notifications/services/notification_storage.dart';
import 'package:almeriarutav02/features/notifications/viewmodels/notifications_viewmodel.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';

void main() {
  group('NotificationsViewModel', () {
    test('load hydrates settings and calls favorites + scheduler', () async {
      final storage = _FakeNotificationStorage(
        loadResult: const NotificationSettings(
          recharge: RechargeReminderSettings(
            enabled: true,
            monthlyExpiryDateIso: '2026-05-01',
            hour: 9,
            minute: 30,
          ),
          arrival: ArrivalAlertSettings.defaults(),
        ),
      );
      final scheduler = _FakeNotificationSchedulerService();
      final favorites = _FakeFavoritesViewModel();
      final vm = NotificationsViewModel(
        storage: storage,
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: scheduler,
        favoritesViewModel: favorites,
      );

      await vm.load();

      expect(favorites.loadCalled, isTrue);
      expect(vm.settings.recharge.enabled, isTrue);
      expect(vm.draft.recharge.hour, 9);
      expect(scheduler.appliedSettings.length, 1);
      expect(vm.loading, isFalse);
    });

    test('setArrivalStop resets selected line and marks pending changes', () {
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(),
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      vm.setArrivalLine(id: 'L1', name: 'L1');
      vm.setArrivalStop(id: '100', name: 'Parada Centro');

      expect(vm.draft.arrival.stopId, '100');
      expect(vm.draft.arrival.stopName, 'Parada Centro');
      expect(vm.draft.arrival.lineId, isNull);
      expect(vm.draft.arrival.lineName, isNull);
      expect(vm.hasPendingChanges, isTrue);
    });

    test('acceptChanges persists draft and applies scheduler', () async {
      final storage = _FakeNotificationStorage();
      final scheduler = _FakeNotificationSchedulerService();
      final vm = NotificationsViewModel(
        storage: storage,
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: scheduler,
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      vm.setRechargeEnabled(true);
      await vm.acceptChanges();

      expect(storage.savedSettings.length, 1);
      expect(storage.savedSettings.first.recharge.enabled, isTrue);
      expect(scheduler.appliedSettings.length, 1);
      expect(vm.hasPendingChanges, isFalse);
    });

    test('refreshRemoteNotifications with token updates list from backend', () async {
      final backend = _FakeBackendNotificationsApiService(
        notifications: [
          UserNotification.fromJson({
            'id': 1,
            'title': 'Hola',
            'body': 'Test',
            'isRead': false,
            'created_at': '2026-04-05T10:00:00.000',
          }),
        ],
      );
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(),
        backendNotifications: backend,
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
        token: 'token-1',
      );

      await vm.refreshRemoteNotifications();

      expect(vm.remoteNotifications, hasLength(1));
      expect(vm.remoteNotifications.first.id, 1);
    });

    test('discardChanges restores draft from settings snapshot', () async {
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(
          loadResult: const NotificationSettings(
            recharge: RechargeReminderSettings.defaults(),
            arrival: ArrivalAlertSettings.defaults(),
          ),
        ),
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      await vm.load();
      vm.setRechargeEnabled(true);
      expect(vm.hasPendingChanges, isTrue);

      vm.discardChanges();
      expect(vm.hasPendingChanges, isFalse);
      expect(vm.draft.recharge.enabled, isFalse);
    });

    test('clearArrivalTarget nullifies stop and line selection', () {
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(),
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      vm.setArrivalStop(id: '100', name: 'Parada Centro');
      vm.setArrivalLine(id: 'L1', name: 'L1');
      vm.clearArrivalTarget();

      expect(vm.draft.arrival.stopId, isNull);
      expect(vm.draft.arrival.stopName, isNull);
      expect(vm.draft.arrival.lineId, isNull);
      expect(vm.draft.arrival.lineName, isNull);
    });

    test('mark/delete with token call backend and refresh notifications', () async {
      final backend = _FakeBackendNotificationsApiService(
        notifications: [
          UserNotification.fromJson({
            'id': 2,
            'title': 'Noti',
            'body': 'Body',
            'isRead': false,
            'created_at': '2026-04-05T10:00:00.000',
          }),
        ],
      );

      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(),
        backendNotifications: backend,
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
        token: 'token-1',
      );

      await vm.markRemoteNotificationAsRead(2);
      await vm.deleteRemoteNotification(2);

      expect(backend.markedIds, [2]);
      expect(backend.deletedIds, [2]);
      expect(vm.remoteNotifications, hasLength(1));
    });

    test('load sets error when storage fails and turns loading off', () async {
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(loadError: Exception('load failed')),
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      await vm.load();

      expect(vm.loading, isFalse);
      expect(vm.error, isNotNull);
      expect(vm.error, contains('load failed'));
    });

    test('acceptChanges sets error when save fails and still updates local snapshot', () async {
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(saveError: Exception('save failed')),
        backendNotifications: _FakeBackendNotificationsApiService(),
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      vm.setRechargeEnabled(true);
      await vm.acceptChanges();

      expect(vm.error, isNotNull);
      expect(vm.error, contains('save failed'));
      expect(vm.hasPendingChanges, isFalse);
    });

    test('refreshRemoteNotifications captures backend fetch error', () async {
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(),
        backendNotifications: _FakeBackendNotificationsApiService(
          fetchError: Exception('fetch failed'),
        ),
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
        token: 'token-1',
      );

      await vm.refreshRemoteNotifications();

      expect(vm.error, isNotNull);
      expect(vm.error, contains('fetch failed'));
    });

    test('mark/delete without token skip backend calls', () async {
      final backend = _FakeBackendNotificationsApiService();
      final vm = NotificationsViewModel(
        storage: _FakeNotificationStorage(),
        backendNotifications: backend,
        apiService: _FakeBusApiService(),
        notificationScheduler: _FakeNotificationSchedulerService(),
        favoritesViewModel: _FakeFavoritesViewModel(),
      );

      await vm.markRemoteNotificationAsRead(7);
      await vm.deleteRemoteNotification(7);

      expect(backend.markedIds, isEmpty);
      expect(backend.deletedIds, isEmpty);
    });
  });
}

class _FakeNotificationStorage extends NotificationStorage {
  _FakeNotificationStorage({
    NotificationSettings? loadResult,
    this.loadError,
    this.saveError,
  }) : _loadResult = loadResult ?? const NotificationSettings.defaults();

  final NotificationSettings _loadResult;
  final Object? loadError;
  final Object? saveError;
  final List<NotificationSettings> savedSettings = [];

  @override
  Future<NotificationSettings> load() async {
    if (loadError != null) throw loadError!;
    return _loadResult;
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    if (saveError != null) throw saveError!;
    savedSettings.add(settings);
  }
}

class _FakeNotificationSchedulerService extends NotificationSchedulerService {
  _FakeNotificationSchedulerService() : super();

  final List<NotificationSettings> appliedSettings = [];

  @override
  Future<void> applySchedules(NotificationSettings settings) async {
    appliedSettings.add(settings);
  }
}

class _FakeBackendNotificationsApiService extends BackendNotificationsApiService {
  _FakeBackendNotificationsApiService({
    List<UserNotification>? notifications,
    this.fetchError,
  }) : _notifications = notifications ?? <UserNotification>[];

  final List<UserNotification> _notifications;
  final Object? fetchError;
  final List<int> markedIds = [];
  final List<int> deletedIds = [];

  @override
  Future<List<UserNotification>> fetchNotifications({
    required String token,
    bool unreadOnly = false,
  }) async {
    if (fetchError != null) throw fetchError!;
    return _notifications;
  }

  @override
  Future<void> markAsRead({required String token, required int notificationId}) async {
    markedIds.add(notificationId);
  }

  @override
  Future<void> deleteNotification({required String token, required int notificationId}) async {
    deletedIds.add(notificationId);
  }
}

class _FakeFavoritesViewModel extends FavoritesViewModel {
  bool loadCalled = false;

  @override
  Future<void> load() async {
    loadCalled = true;
  }
}

class _FakeBusApiService extends BusApiService {
  @override
  Future<List<LineModel>> getLines({bool forceRefresh = false}) async => [];

  @override
  Future<List<StopModel>> getLineStops(String lineId, {bool forceRefresh = false}) async => [];

  @override
  Future<Map<String, int>> getStopArrivals(String stopId, {int limit = 5}) async => {};
}
