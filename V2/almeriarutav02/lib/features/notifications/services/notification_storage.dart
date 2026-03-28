import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings.dart';

class NotificationStorage {
  static const _key = 'notification_settings';

  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const NotificationSettings.defaults();
    }
    return NotificationSettings.fromStorageString(raw);
  }

  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, settings.toStorageString());
  }
}
