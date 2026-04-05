import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/services/bus_api_service.dart';
import '../models/notification_settings.dart';
import 'local_notification_service.dart';

class ArrivalObserverService {
  static final ArrivalObserverService _instance = ArrivalObserverService._internal();

  factory ArrivalObserverService() => _instance;

  ArrivalObserverService._internal({
    BusApiService? apiService,
    LocalNotificationService? localNotifications,
  })  : _apiService = apiService ?? BusApiService(),
        _localNotifications = localNotifications ?? LocalNotificationService();

  @visibleForTesting
  ArrivalObserverService.testing({
    required BusApiService apiService,
    required LocalNotificationService localNotifications,
  })  : _apiService = apiService,
        _localNotifications = localNotifications;

  final BusApiService _apiService;
  final LocalNotificationService _localNotifications;

  Timer? _timer;
  String? _observedSignature;
  String? _lastTriggeredSignature;
  bool _busy = false;

  void stopObserving() {
    _timer?.cancel();
    _timer = null;
    _observedSignature = null;
    _lastTriggeredSignature = null;
  }

  Future<void> updateFromSettings(ArrivalAlertSettings settings) async {
    stopObserving();

    if (!settings.enabled ||
        settings.lineId == null ||
        settings.lineName == null ||
        settings.stopId == null ||
        settings.stopName == null) {
      await _localNotifications.cancelArrivalAlert();
      return;
    }

    await _localNotifications.requestPermissionsIfNeeded();
    await _observeOnce(settings);

    _observedSignature = _signature(settings);
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      _observeOnce(settings);
    });
  }

  Future<void> _observeOnce(ArrivalAlertSettings settings) async {
    if (_busy) return;
    _busy = true;
    try {
      if (!settings.enabled ||
          settings.lineId == null ||
          settings.lineName == null ||
          settings.stopId == null ||
          settings.stopName == null) {
        return;
      }

      final lineId = settings.lineId!;
      final lineName = settings.lineName!;
      final stopId = settings.stopId!;
      final stopName = settings.stopName!;
      final leadMinutes = settings.leadMinutes;

      final signature = _signature(settings);
      if (_observedSignature != null && _observedSignature != signature) {
        return;
      }

      final arrivals = await _apiService.getStopArrivals(stopId, limit: 8);
      final minutesToArrive = arrivals[lineId];
      if (minutesToArrive == null) {
        return;
      }

      if (minutesToArrive <= leadMinutes) {
        if (minutesToArrive > 0 && _lastTriggeredSignature != signature) {
          await _localNotifications.showArrivalAlertNow(
            lineName: lineName,
            stopName: stopName,
            leadMinutes: leadMinutes,
          );
          _lastTriggeredSignature = signature;
        }
        return;
      }

      final scheduledTime = DateTime.now().add(Duration(minutes: minutesToArrive - leadMinutes));
      await _localNotifications.scheduleOneShotArrivalAlert(
        scheduledTime: scheduledTime,
        lineName: lineName,
        stopName: stopName,
        leadMinutes: leadMinutes,
      );
    } finally {
      _busy = false;
    }
  }

  String _signature(ArrivalAlertSettings settings) {
    return '${settings.stopId}|${settings.lineId}|${settings.leadMinutes}';
  }
}