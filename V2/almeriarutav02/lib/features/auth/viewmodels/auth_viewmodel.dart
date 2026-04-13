import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/auth_api_service.dart';

class AuthViewModel extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _avatarIconKey = 'auth_avatar_icon';

  final AuthApiService _api = AuthApiService();

  bool _initialized = false;
  bool _loading = false;
  String? _error;
  String? _token;
  AppUser? _user;
  IconData _avatarIcon = Icons.person;

  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;
  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isGuest => _user?.guest == true;
  IconData get avatarIcon => _avatarIcon;

  Future<void> initialize() async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final rawUser = prefs.getString(_userKey);
      final avatarCodePoint = prefs.getInt(_avatarIconKey);
      if (avatarCodePoint != null) {
        _avatarIcon = IconData(avatarCodePoint, fontFamily: 'MaterialIcons');
      }
      if (_token != null && rawUser != null) {
        _user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
        try {
          _user = await _api.me(_token!);
          await _saveSession(_token!, _user!);
        } catch (_) {
          await logout();
        }
      }
    } finally {
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final (token, user) = await _api.login(identifier: identifier, password: password);
      _token = token;
      _user = user;
      await _saveSession(token, user);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String username, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final (token, user) = await _api.register(email: email, username: username, password: password);
      _token = token;
      _user = user;
      await _saveSession(token, user);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> continueAsGuest() async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final (token, user) = await _api.guest();
      _token = token;
      _user = user;
      await _saveSession(token, user);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String email,
    required String username,
  }) async {
    if (_token == null || _user == null || isGuest) {
      _error = 'Debes iniciar sesión con una cuenta registrada';
      notifyListeners();
      return false;
    }

    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final (newToken, updatedUser) = await _api.updateProfile(
        token: _token!,
        email: email,
        username: username,
      );
      _token = newToken;
      _user = updatedUser;
      await _saveSession(newToken, updatedUser);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null || _user == null || isGuest) {
      _error = 'Debes iniciar sesión con una cuenta registrada';
      notifyListeners();
      return false;
    }

    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await _api.changePassword(
        token: _token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setAvatarIcon(IconData icon) async {
    _avatarIcon = icon;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarIconKey, icon.codePoint);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _saveSession(String token, AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
