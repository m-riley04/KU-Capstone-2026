/// No-op poller on web; notifications are fetched directly by the controller.
class NotificationPollerService {
  bool get isRunning => false;

  Future<void> start({double intervalSeconds = 5.0}) async {}

  Future<void> stop() async {}
}