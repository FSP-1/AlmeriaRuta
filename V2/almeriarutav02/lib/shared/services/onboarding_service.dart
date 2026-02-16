import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _mapKey = 'map_onboarding_done';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mapKey) ?? false;
  }

  static Future<void> setDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mapKey, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mapKey);
  }
}
