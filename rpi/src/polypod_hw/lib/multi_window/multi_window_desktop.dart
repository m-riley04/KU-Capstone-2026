import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'multi_window_stub.dart';

class DesktopWindowController implements PolypodWindowController {
  DesktopWindowController(this._inner);

  final WindowController _inner;

  @override
  String get windowId => _inner.windowId;

  @override
  String get arguments => _inner.arguments;

  @override
  Future<void> setMethodHandler(WindowMethodCallHandler handler) async {
    await _inner.setWindowMethodHandler((call) async {
      return handler(call.method, call.arguments);
    });
  }

  @override
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) {
    return _inner.invokeMethod(method, arguments);
  }

  @override
  Future<void> show() => _inner.show();
}

class DesktopMultiWindow implements PolypodMultiWindow {
  const DesktopMultiWindow();

  @override
  bool get isSupported => true;

  @override
  Future<PolypodWindowController?> fromCurrentEngine() async {
    final controller = await WindowController.fromCurrentEngine();
    return DesktopWindowController(controller);
  }

  @override
  Future<PolypodWindowController?> fromWindowId(String windowId) async {
    final controller = WindowController.fromWindowId(windowId);
    return DesktopWindowController(controller);
  }

  @override
  Future<List<PolypodWindowController>> getAll() async {
    final controllers = await WindowController.getAll();
    return controllers.map(DesktopWindowController.new).toList();
  }

  @override
  Future<PolypodWindowController?> create({
    required String arguments,
    bool hiddenAtLaunch = false,
  }) async {
    final controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: hiddenAtLaunch,
        arguments: arguments,
      ),
    );
    return DesktopWindowController(controller);
  }
}

PolypodMultiWindow createMultiWindowImpl() => const DesktopMultiWindow();
