import 'package:flutter/material.dart';
import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/notices_api_service.dart';

class OperarioViewModel extends ChangeNotifier {
  final NoticesApiService _api;
  final BusApiService _busApi;
  final String? _token;
  final int? _userId;

  OperarioViewModel({
    NoticesApiService? api,
    BusApiService? busApi,
    String? token,
    int? userId,
  })  : _api = api ?? NoticesApiService(),
        _busApi = busApi ?? BusApiService(),
        _token = token,
        _userId = userId;

  bool _loading = false;
  String? _error;
  String? _successMessage;
  List<NoticeModel> _notices = [];
  List<DisabledStopModel> _disabledStops = [];
  List<LineModel> _lines = [];
  List<StopModel> _lineStops = [];
  List<StopModel> _allStops = [];
  String? _selectedLineId;
  final Set<String> _selectedLineStopIds = <String>{};
  String _stopSearchQuery = '';
  StopModel? _selectedStopForNotice;

  // Form fields
  String _noticeTitle = '';
  String _noticeMessage = '';
  String _noticeType = 'GENERAL';
  String? _noticeRelatedId;

  String _stopId = '';
  String _stopName = '';
  String _stopReason = '';

  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  List<NoticeModel> get notices => _notices;
  List<NoticeModel> get sortedNotices {
    final ordered = [..._notices];
    ordered.sort((a, b) {
      final byType = _noticeTypeOrder(a.type).compareTo(_noticeTypeOrder(b.type));
      if (byType != 0) return byType;
      return b.createdAt.compareTo(a.createdAt);
    });
    return ordered;
  }
  List<DisabledStopModel> get disabledStops => _disabledStops;
  List<LineModel> get lines => _lines;
  List<StopModel> get lineStops => _lineStops;
  String? get selectedLineId => _selectedLineId;
  Set<String> get selectedLineStopIds => _selectedLineStopIds;
  String get stopSearchQuery => _stopSearchQuery;
  StopModel? get selectedStopForNotice => _selectedStopForNotice;

  List<StopModel> get filteredStopsForSearch {
    final q = _stopSearchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return _allStops.take(20).toList();
    }
    return _allStops.where((s) {
      final coord = '${s.lat.toStringAsFixed(5)},${s.lon.toStringAsFixed(5)}';
      return s.id.toLowerCase().contains(q) || s.name.toLowerCase().contains(q) || coord.contains(q);
    }).take(30).toList();
  }

  // Form getters
  String get noticeTitle => _noticeTitle;
  String get noticeMessage => _noticeMessage;
  String get noticeType => _noticeType;
  String? get noticeRelatedId => _noticeRelatedId;

  String get stopId => _stopId;
  String get stopName => _stopName;
  String get stopReason => _stopReason;

  List<String> get noticeTypes => ['GENERAL', 'LINEA', 'PARADA', 'TURISMO'];

  int _noticeTypeOrder(String type) {
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

  // Form setters
  void setNoticeTitle(String value) {
    _noticeTitle = value;
    notifyListeners();
  }

  void setNoticeMessage(String value) {
    _noticeMessage = value;
    notifyListeners();
  }

  void setNoticeType(String value) {
    _noticeType = value;
    if (_noticeType != 'LINEA') {
      _selectedLineId = null;
      _lineStops = [];
      _selectedLineStopIds.clear();
    }
    if (_noticeType != 'PARADA') {
      _selectedStopForNotice = null;
      _stopSearchQuery = '';
    }
    notifyListeners();
  }

  void setNoticeRelatedId(String? value) {
    _noticeRelatedId = value;
    notifyListeners();
  }

  void setStopId(String value) {
    _stopId = value;
    notifyListeners();
  }

  void setStopName(String value) {
    _stopName = value;
    notifyListeners();
  }

  void setStopReason(String value) {
    _stopReason = value;
    notifyListeners();
  }

  Future<void> selectLine(String? lineId) async {
    _selectedLineId = lineId;
    _selectedLineStopIds.clear();
    _lineStops = [];
    _noticeRelatedId = lineId;

    if (lineId != null && lineId.isNotEmpty) {
      try {
        _lineStops = await _busApi.getLineStops(lineId);
      } catch (_) {
        _lineStops = [];
      }
    }
    notifyListeners();
  }

  void toggleLineStop(String stopId, bool selected) {
    if (selected) {
      _selectedLineStopIds.add(stopId);
    } else {
      _selectedLineStopIds.remove(stopId);
    }
    notifyListeners();
  }

  void setStopSearchQuery(String value) {
    _stopSearchQuery = value;
    notifyListeners();
  }

  void selectStopForNotice(StopModel stop) {
    _selectedStopForNotice = stop;
    _noticeRelatedId = stop.id;
    notifyListeners();
  }

  void resetNoticeForm() {
    _noticeTitle = '';
    _noticeMessage = '';
    _noticeType = 'GENERAL';
    _noticeRelatedId = null;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void resetStopForm() {
    _stopId = '';
    _stopName = '';
    _stopReason = '';
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      _notices = await _api.listNotices(token: _token);
      _disabledStops = await _api.listDisabledStops(token: _token);
      _lines = await _busApi.getLines();
      final byStopId = <String, StopModel>{};
      for (final line in _lines) {
        for (final stop in line.stops) {
          byStopId.putIfAbsent(stop.id, () => stop);
        }
      }
      _allStops = byStopId.values.toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool validateNoticeForm() {
    _error = null;
    
    if (_noticeTitle.trim().isEmpty) {
      _error = 'El título es requerido';
      notifyListeners();
      return false;
    }
    
    if (_noticeMessage.trim().isEmpty) {
      _error = 'El mensaje es requerido';
      notifyListeners();
      return false;
    }
    
    if (_noticeTitle.length > 100) {
      _error = 'El título no puede exceder 100 caracteres';
      notifyListeners();
      return false;
    }
    
    if (_noticeMessage.length > 500) {
      _error = 'El mensaje no puede exceder 500 caracteres';
      notifyListeners();
      return false;
    }

    if (_noticeType == 'LINEA') {
      if ((_selectedLineId ?? '').isEmpty) {
        _error = 'Selecciona una línea';
        notifyListeners();
        return false;
      }
      if (_selectedLineStopIds.isEmpty) {
        _error = 'Selecciona al menos una parada afectada';
        notifyListeners();
        return false;
      }
    }

    if (_noticeType == 'PARADA' && _selectedStopForNotice == null) {
      _error = 'Selecciona una parada con el buscador';
      notifyListeners();
      return false;
    }
    
    return true;
  }

  bool validateStopForm() {
    _error = null;
    
    if (_stopId.trim().isEmpty) {
      _error = 'El ID de la parada es requerido';
      notifyListeners();
      return false;
    }
    
    if (_stopName.trim().isEmpty) {
      _error = 'El nombre de la parada es requerido';
      notifyListeners();
      return false;
    }
    
    if (_stopReason.trim().isEmpty) {
      _error = 'La razón es requerida';
      notifyListeners();
      return false;
    }
    
    return true;
  }

  Future<bool> createNotice() async {
    if (!validateNoticeForm()) {
      return false;
    }

    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final relatedId = _noticeType == 'LINEA'
          ? _selectedLineId
          : (_noticeType == 'PARADA' ? _selectedStopForNotice?.id : _noticeRelatedId);

      final enrichedMessage = _noticeType == 'LINEA'
          ? '${_noticeMessage.trim()}\nParadas afectadas: ${_lineStops.where((s) => _selectedLineStopIds.contains(s.id)).map((s) => s.name).join(', ')}'
          : (_noticeType == 'PARADA' && _selectedStopForNotice != null)
              ? '${_noticeMessage.trim()}\nParada: ${_selectedStopForNotice!.name} (${_selectedStopForNotice!.lat.toStringAsFixed(5)}, ${_selectedStopForNotice!.lon.toStringAsFixed(5)})'
              : _noticeMessage.trim();

      await _api.createNotice(
        token: _token,
        title: _noticeTitle.trim(),
        message: enrichedMessage,
        type: _noticeType,
        relatedId: relatedId,
      );
      
      _successMessage = 'Aviso creado exitosamente';
      resetNoticeForm();
      await loadData(); // Reload
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> disableStop() async {
    if (!validateStopForm()) {
      return false;
    }

    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _api.disableStop(
        token: _token,
        stopId: _stopId.trim(),
        stopName: _stopName.trim(),
        reason: _stopReason.trim(),
        userId: _userId,
      );
      
      _successMessage = 'Parada deshabilitada exitosamente';
      resetStopForm();
      await loadData(); // Reload
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> enableStop(String stopId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.enableStop(token: _token, stopId: stopId);
      _successMessage = 'Parada habilitada exitosamente';
      await loadData(); // Reload
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
      _successMessage = 'Aviso desactivado exitosamente';
      await loadData(); // Reload
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
