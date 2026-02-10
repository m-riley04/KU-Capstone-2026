import 'dart:async';
import 'package:flutter/material.dart';

class ClockTimerController extends ChangeNotifier {
  Duration _selectedDuration = Duration.zero;
  Duration _remaining = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;

  Duration get selectedDuration => _selectedDuration;
  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;

  void updateSelection(Duration value) {
    _selectedDuration = value;
    if (!_isRunning) {
      _remaining = value;
    }
    notifyListeners();
  }

  void start() {
    if (_isRunning) {
      return;
    }

    if (_remaining == Duration.zero) {
      _remaining = _selectedDuration;
    }

    if (_remaining == Duration.zero) {
      notifyListeners();
      return;
    }

    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        _remaining = Duration.zero;
        _isRunning = false;
        timer.cancel();
      } else {
        _remaining = next;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _remaining = _selectedDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
