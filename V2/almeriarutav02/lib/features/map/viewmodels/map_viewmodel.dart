import 'package:flutter/material.dart';
import '../models/location_model.dart';

class MapViewModel extends ChangeNotifier {
  LocationModel? _selectedLocation;
  bool _isLoading = false;
  String? _errorMessage;

  LocationModel? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedLocation(LocationModel location) {
    _selectedLocation = location;
    _errorMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedLocation = null;
    _errorMessage = null;
    notifyListeners();
  }
}