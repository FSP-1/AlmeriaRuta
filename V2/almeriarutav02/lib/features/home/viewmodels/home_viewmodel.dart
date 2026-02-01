import 'package:flutter/foundation.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';

class HomeViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();
  
  List<LineModel> _lines = [];
  bool _isLoading = false;
  String? _error;

  List<LineModel> get lines => _lines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lines = await _apiService.getLines();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<StopModel>> getLineStops(String lineId) async {
    return await _apiService.getLineStops(lineId);
  }
}