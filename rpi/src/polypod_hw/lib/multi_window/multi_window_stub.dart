typedef WindowMethodCallHandler = Future<dynamic> Function(
  String method,
  dynamic arguments,
);

abstract class PolypodWindowController {
  String get windowId;
  String get arguments;

  Future<void> setMethodHandler(WindowMethodCallHandler handler);
  Future<dynamic> invokeMethod(String method, [dynamic arguments]);
  Future<void> show();
}

abstract class PolypodMultiWindow {
  bool get isSupported;

  Future<PolypodWindowController?> fromCurrentEngine();
  Future<PolypodWindowController?> fromWindowId(String windowId);
  Future<List<PolypodWindowController>> getAll();
  Future<PolypodWindowController?> create({
    required String arguments,
    bool hiddenAtLaunch,
  });
}

class _UnsupportedWindowController implements PolypodWindowController {
  @override
  String get windowId => '';

  @override
  String get arguments => '';

  @override
  Future<void> setMethodHandler(WindowMethodCallHandler handler) async {}

  @override
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
    return null;
  }

  @override
  Future<void> show() async {}
}

class UnsupportedMultiWindow implements PolypodMultiWindow {
  const UnsupportedMultiWindow();

  @override
  bool get isSupported => false;

  @override
  Future<PolypodWindowController?> fromCurrentEngine() async {
    return _UnsupportedWindowController();
  }

  @override
  Future<PolypodWindowController?> fromWindowId(String windowId) async {
    return _UnsupportedWindowController();
  }

  @override
  Future<List<PolypodWindowController>> getAll() async => const [];

  @override
  Future<PolypodWindowController?> create({
    required String arguments,
    bool hiddenAtLaunch = false,
  }) async {
    return null;
  }
}

PolypodMultiWindow createMultiWindowImpl() => const UnsupportedMultiWindow();
