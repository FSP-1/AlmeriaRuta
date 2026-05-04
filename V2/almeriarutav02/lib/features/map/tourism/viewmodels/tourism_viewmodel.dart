import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/tourist_places.dart';
import '../models/tourist_place.dart';

class TourismViewModel extends ChangeNotifier {
  static const _enabledKey = 'tourism_filters_enabled';
  static const _categoryKey = 'tourism_filters_category';

  bool _isEnabled = false;
  TouristCategory? _selectedCategory;
  bool _loaded = false;

  bool get isEnabled => _isEnabled;
  TouristCategory? get selectedCategory => _selectedCategory;
  bool get isLoaded => _loaded;

  List<TouristPlace> get places => TouristData.places;

  List<TouristPlace> get filteredPlaces {
    if (!_isEnabled) return const [];
    if (_selectedCategory == null) return places;
    return places.where((p) => p.category == _selectedCategory).toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? false;

    final savedCategory = prefs.getString(_categoryKey);
    _selectedCategory = _categoryFromName(savedCategory);

    _loaded = true;
    notifyListeners();
  }

  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    _saveState();
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _saveState();
    notifyListeners();
  }

  void setCategory(TouristCategory? category) {
    _selectedCategory = category;
    _saveState();
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, _isEnabled);
    if (_selectedCategory == null) {
      await prefs.remove(_categoryKey);
    } else {
      await prefs.setString(_categoryKey, _selectedCategory!.name);
    }
  }

  TouristCategory? _categoryFromName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final category in TouristCategory.values) {
      if (category.name == name) return category;
    }
    return null;
  }
}
