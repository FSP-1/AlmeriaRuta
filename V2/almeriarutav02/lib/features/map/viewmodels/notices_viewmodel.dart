import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/notices_api_service.dart';

class NoticesViewModel extends ChangeNotifier {
  final NoticesApiService _api;
  final String? _token;

  NoticesViewModel({NoticesApiService? api, String? token})
      : _api = api ?? NoticesApiService(),
        _token = token;

  bool _loading = false;
  String? _error;
  List<NoticeModel> _notices = [];
  List<DisabledStopModel> _disabledStops = [];
  Timer? _refreshTimer;

  bool get loading => _loading;
  String? get error => _error;
  List<NoticeModel> get notices => _notices;
  List<NoticeModel> get orderedNotices {
    final ordered = [..._notices];
    ordered.sort((a, b) {
      final byType = _typePriority(a.type).compareTo(_typePriority(b.type));
      if (byType != 0) return byType;
      return b.createdAt.compareTo(a.createdAt);
    });
    return ordered;
  }
  List<DisabledStopModel> get disabledStops => _disabledStops;

  int _typePriority(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return 0;
      case 'TURISMO':
        return 1;
      case 'LINEA':
        return 2;
      case 'PARADA':
        return 3;
      default:
        return 99;
    }
  }

  // For marquee display
  String get marqueeText {
    if (_notices.isEmpty && _disabledStops.isEmpty) {
      return '';
    }

    final List<String> messages = [];

    for (var notice in orderedNotices) {
      messages.add('[${notice.type}] ${notice.title}: ${notice.message}');
    }

    for (var stop in _disabledStops) {
      messages.add('[PARADA] ${stop.stopName} deshabilitada: ${stop.reason}');
    }

    return messages.join(' --- ');
  }

  bool get hasNotices => _notices.isNotEmpty || _disabledStops.isNotEmpty;

  Future<void> loadNotices() async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      _notices = await _api.listNotices(token: _token);
      _disabledStops = await _api.listDisabledStops(token: _token);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createNotice({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await _api.createNotice(
        token: _token,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );
      await loadNotices(); // Reload after creation
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateNotice(String noticeId) async {
    try {
      await _api.deactivateNotice(token: _token, noticeId: noticeId);
      _notices.removeWhere((n) => n.id == noticeId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> disableStop({
    required String stopId,
    required String stopName,
    String? reason,
    int? userId,
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await _api.disableStop(
        token: _token,
        stopId: stopId,
        stopName: stopName,
        reason: reason,
        userId: userId,
      );
      await loadNotices(); // Reload after disabling
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> enableStop(String stopId) async {
    try {
      await _api.enableStop(token: _token, stopId: stopId);
      _disabledStops.removeWhere((s) => s.stopId == stopId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 120)}) {
    _refreshTimer?.cancel();
    loadNotices(); // Load immediately
    _refreshTimer = Timer.periodic(interval, (_) {
      loadNotices();
    });
  }

  // Token is optional; operations call API with nullable token.

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
