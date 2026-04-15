import 'dart:convert';
import 'dart:io';

Future<String> loadNotificationUserId() async {
  final settingsFile = File(_notificationSettingsPath());
  if (!await settingsFile.exists()) {
    return '';
  }

  try {
    final raw = await settingsFile.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded['user_id']?.toString().trim() ?? '';
    }
  } catch (_) {
    return '';
  }

  return '';
}

Future<void> saveNotificationUserId(String userId) async {
  final settingsFile = File(_notificationSettingsPath());
  await settingsFile.parent.create(recursive: true);
  await settingsFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert({'user_id': userId}),
  );
}

Future<void> clearNotificationState() async {
  final currentNotificationFile = File(_currentNotificationPath());
  await currentNotificationFile.parent.create(recursive: true);
  await currentNotificationFile.writeAsString('{}');

  final pollerStateFile = File(_notificationPollStatePath());
  if (await pollerStateFile.exists()) {
    await pollerStateFile.delete();
  }
}

String _notificationSettingsPath() {
  final currentDir = Directory.current.path;
  final settingsPath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}notification_settings.json';
  return File(settingsPath).absolute.path;
}

String _currentNotificationPath() {
  final currentDir = Directory.current.path;
  final notifPath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}current_notification.json';
  return File(notifPath).absolute.path;
}

String _notificationPollStatePath() {
  final currentDir = Directory.current.path;
  final statePath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}.notification_poll_state.json';
  return File(statePath).absolute.path;
}