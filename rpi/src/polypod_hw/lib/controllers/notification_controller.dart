// RILEY ANDERSON
// 02/17/2026
// Controller for managing notification state and platform-specific polling

export 'notification_controller_io.dart'
    if (dart.library.html) 'notification_controller_web.dart';
