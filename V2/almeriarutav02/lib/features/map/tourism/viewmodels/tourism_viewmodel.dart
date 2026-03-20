import 'package:flutter/material.dart';
import '../data/tourist_places.dart';
import '../models/tourist_place.dart';

class TourismViewModel extends ChangeNotifier {
  bool _isEnabled = false;
  TouristCategory? _selectedCategory;

  bool get isEnabled => _isEnabled;
  TouristCategory? get selectedCategory => _selectedCategory;

  List<TouristPlace> get places => TouristData.places;

  List<TouristPlace> get filteredPlaces {
    if (!_isEnabled) return const [];
    if (_selectedCategory == null) return places;
    return places.where((p) => p.category == _selectedCategory).toList();
  }

  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  void setCategory(TouristCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
