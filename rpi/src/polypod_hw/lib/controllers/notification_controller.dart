// RILEY ANDERSON
// 02/17/2026
// Controller for managing notification state and file monitoring

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/notification_models.dart';

/// Controller that monitors notification file and manages notification state
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

  /// Start watching the notification file for changes
  void _startWatching() {
    // Check file every 500ms for changes
    _fileWatchTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _checkForUpdates(),
    );
  }

  /// Check if the notification file has been updated
  Future<void> _checkForUpdates() async {
    try {
      // Resolve the full path
      final file = File(_resolveFilePath());

      if (!await file.exists()) {
        return;
      }

      final contents = await file.readAsString();

      // Only parse if content has changed
      if (contents != _lastFileContent) {
        _lastFileContent = contents;
        final notification = await parseNotificationFromFile(_resolveFilePath());

        if (notification != null) {
          _currentNotification = notification;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for notification updates: $e');
      }
    }
  }

  /// Resolve the notification file path relative to the app
  String _resolveFilePath() {
    // If absolute path, use as-is
    if (notificationFilePath.startsWith('/') ||
        notificationFilePath.contains(':\\')) {
      return notificationFilePath;
    }

    // Resolve relative to the Flutter app directory
    // From polypod_hw, go up one level to src, then into notif
    final currentDir = Directory.current.path;
    // if (kDebugMode) {
    //   print('Looking for notification file at: $currentDir');
    // }
    
    // Construct path: ../notif/current_notification.json from polypod_hw directory
    final notifPath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}current_notification.json';
    final normalizedPath = File(notifPath).absolute.path;
    
    // if (kDebugMode) {
    //   print('Resolved notification path: $normalizedPath');
    // }
    
    return normalizedPath;
  }

  /// Manually refresh notification
  Future<void> refresh() async {
    await _checkForUpdates();
  }

  /// Clear current notification
  void clearNotification() {
    _currentNotification = null;
    notifyListeners();
  }

  /// Dismiss notification with auto-clear after duration
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
