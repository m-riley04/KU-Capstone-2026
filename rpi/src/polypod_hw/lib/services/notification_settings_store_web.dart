import 'package:shared_preferences/shared_preferences.dart';

const _notificationUserIdKey = 'polypod_notification_user_id';

Future<String> loadNotificationUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_notificationUserIdKey) ?? '';
}

Future<void> saveNotificationUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  if (userId.isEmpty) {
    await prefs.remove(_notificationUserIdKey);
    return;
  }

  await prefs.setString(_notificationUserIdKey, userId);
}

Future<void> clearNotificationState() async {
  // No file-backed bridge state exists on web.
}