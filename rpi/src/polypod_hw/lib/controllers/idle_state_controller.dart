import 'dart:async';
import 'package:flutter/foundation.dart';

/// Controller for managing idle state and timeout
class IdleStateController extends ChangeNotifier {
  Timer? _idleTimer;
  final Duration idleTimeout;
  bool _isIdle = true;
  VoidCallback? _onIdleCallback;

  IdleStateController({
    this.idleTimeout = const Duration(seconds: 30),
  });

  bool get isIdle => _isIdle;

  /// Set the callback to be called when entering idle state
  void setIdleCallback(VoidCallback callback) {
    _onIdleCallback = callback;
  }

  /// Reset the idle timer (call this on any user interaction)
  void resetIdleTimer() {
    _isIdle = false;
    notifyListeners();
    
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () {
      _enterIdleState();
    });
  }

  /// Manually enter idle state
  void enterIdleState() {
    _enterIdleState();
  }

  void _enterIdleState() {
    _isIdle = true;
    notifyListeners();
    _onIdleCallback?.call();
  }

  /// Cancel the idle timer
  void cancelTimer() {
    _idleTimer?.cancel();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
