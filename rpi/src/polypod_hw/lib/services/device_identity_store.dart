import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _deviceIdKey = 'polypod_device_id';
const _setupCompleteKey = 'polypod_first_setup_complete';

Future<String> loadOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_deviceIdKey)?.trim() ?? '';
  if (existing.isNotEmpty) {
    return existing;
  }

  final generated = _generateAlphanumericId();
  await prefs.setString(_deviceIdKey, generated);
  return generated;
}

Future<bool> shouldShowFirstTimeSetup() async {
  final prefs = await SharedPreferences.getInstance();
  final setupComplete = prefs.getBool(_setupCompleteKey) ?? false;
  return !setupComplete;
}

Future<void> markFirstTimeSetupComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_setupCompleteKey, true);
}

String _generateAlphanumericId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List<String>.generate(
    8,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}
