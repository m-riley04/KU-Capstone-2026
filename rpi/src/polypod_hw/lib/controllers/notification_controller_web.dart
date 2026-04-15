import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/notification_models.dart';
import '../services/notification_settings_store.dart';

/// Controller that polls the backend notifications endpoint on web.
class NotificationController extends ChangeNotifier {
  static const String _apiBase = 'https://www.polypod.net:3000/notifications';

  NotificationData? _currentNotification;
  Timer? _pollTimer;
  String? _lastResponseSnapshot;
  String? _activeUserId;

  NotificationController() {
    _startWatching();
  }

  NotificationData? get currentNotification => _currentNotification;

  bool get hasNotification => _currentNotification != null;

  void _startWatching() {
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 750),
      (_) => _checkForUpdates(),
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      final userId = (await loadNotificationUserId()).trim();

      if (userId.isEmpty) {
        _activeUserId = null;
        _lastResponseSnapshot = null;
        if (_currentNotification != null) {
          _currentNotification = null;
          notifyListeners();
        }
        return;
      }

      if (_activeUserId != userId) {
        _activeUserId = userId;
        _lastResponseSnapshot = null;
        if (_currentNotification != null) {
          _currentNotification = null;
          notifyListeners();
        }
      }

      final response = await http
          .get(Uri.parse('$_apiBase/$userId'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 204 || response.body.trim().isEmpty) {
        if (_currentNotification != null) {
          _currentNotification = null;
          _lastResponseSnapshot = null;
          notifyListeners();
        }
        return;
      }

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('Notification API returned ${response.statusCode}');
        }
        return;
      }

      final body = response.body;
      if (body == _lastResponseSnapshot) {
        return;
      }

      _lastResponseSnapshot = body;

      final decoded = jsonDecode(body);
      Map<String, dynamic>? notificationJson;

      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          notificationJson = first;
        }
      } else if (decoded is Map<String, dynamic>) {
        notificationJson = decoded;
      }

      if (notificationJson == null) {
        if (_currentNotification != null) {
          _currentNotification = null;
          notifyListeners();
        }
        return;
      }

      final notification = NotificationData.fromJson(notificationJson);
      _currentNotification = notification;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking web notifications: $e');
      }
    }
  }

  Future<void> refresh() async {
    await _checkForUpdates();
  }

  void clearNotification() {
    _currentNotification = null;
    notifyListeners();
  }

  void dismissNotification({Duration? after}) {
    if (after != null) {
      Future.delayed(after, clearNotification);
    } else {
      clearNotification();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}