import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/notification_models.dart';

/// Controller that monitors notification file and manages notification state.
class NotificationController extends ChangeNotifier {
  NotificationData? _currentNotification;
  Timer? _fileWatchTimer;
  String? _lastFileContent;
  final String notificationFilePath;

  NotificationController({
    String? notificationPath,
  }) : notificationFilePath = notificationPath ??
            '../notif/current_notification.json' {
    _startWatching();
  }

  NotificationData? get currentNotification => _currentNotification;

  bool get hasNotification => _currentNotification != null;

  void _startWatching() {
    _fileWatchTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _checkForUpdates(),
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      final file = File(_resolveFilePath());

      if (!await file.exists()) {
        if (_currentNotification != null) {
          _currentNotification = null;
          _lastFileContent = null;
          notifyListeners();
        }
        return;
      }

      final contents = await file.readAsString();

      if (contents != _lastFileContent) {
        _lastFileContent = contents;

        try {
          final decoded = jsonDecode(contents);
          if (decoded is Map<String, dynamic>) {
            final notification = NotificationData.fromJson(decoded);
            _currentNotification = notification;
            notifyListeners();
          } else {
            throw const FormatException('Notification payload was not a map');
          }
        } catch (parseError) {
          if (_currentNotification != null) {
            _currentNotification = null;
            notifyListeners();
          }
          if (kDebugMode) {
            debugPrint('Error parsing notification file: $parseError');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking for notification updates: $e');
      }
    }
  }

  String _resolveFilePath() {
    if (notificationFilePath.startsWith('/') ||
        notificationFilePath.contains(':\\')) {
      return notificationFilePath;
    }

    final currentDir = Directory.current.path;
    final notifPath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}current_notification.json';
    return File(notifPath).absolute.path;
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
    _fileWatchTimer?.cancel();
    super.dispose();
  }
}