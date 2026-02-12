import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';

class FavoritesViewModel extends ChangeNotifier {
  static const _key = 'favorites';

  final List<FavoriteModel> _favorites = [];

  List<FavoriteModel> get favorites => _favorites;

  List<FavoriteModel> get stops =>
      _favorites.where((f) => f.type == FavoriteType.stop).toList();

  List<FavoriteModel> get lines =>
      _favorites.where((f) => f.type == FavoriteType.line).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];

    _favorites.clear();

    for (final item in data) {
      _favorites.add(FavoriteModel.fromJson(json.decode(item)));
    }

    notifyListeners();
  }

  Future<void> add(FavoriteModel fav) async {
    if (isFavorite(fav.id, fav.type)) return;

    _favorites.add(fav);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id, FavoriteType type) async {
    _favorites.removeWhere((f) => f.id == id && f.type == type);
    await _save();
    notifyListeners();
  }

  bool isFavorite(String id, FavoriteType type) {
    return _favorites.any((f) => f.id == id && f.type == type);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _favorites.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_key, list);
  }
}