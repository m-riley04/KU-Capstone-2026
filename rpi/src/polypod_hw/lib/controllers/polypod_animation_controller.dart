import 'dart:async';

import 'package:flutter/foundation.dart';

enum PolypodAnimationState {
  idle,
  eating,
  petting,
  drinking,
}

class PolypodAnimationController extends ChangeNotifier {
  PolypodAnimationController() {
    _startFrameTicker();
  }

  static const int framesPerRow = 4;
  static const int rows = 4;

  static const Duration _frameDuration = Duration(milliseconds: 180);
  static const Duration _actionDuration = Duration(milliseconds: 1500);

  PolypodAnimationState _state = PolypodAnimationState.idle;
  int _frameIndex = 0;

  Timer? _frameTimer;
  Timer? _stateResetTimer;

  PolypodAnimationState get state => _state;
  int get frameIndex => _frameIndex;

  int get rowIndex {
    return switch (_state) {
      PolypodAnimationState.idle => 0,
      PolypodAnimationState.eating => 1,
      PolypodAnimationState.petting => 2,
      PolypodAnimationState.drinking => 3,
    };
  }

  void triggerFeed() => _setTransientState(PolypodAnimationState.eating);

  void triggerPet() => _setTransientState(PolypodAnimationState.petting);

  void triggerWater() => _setTransientState(PolypodAnimationState.drinking);

  void _setTransientState(PolypodAnimationState next) {
    _stateResetTimer?.cancel();
    _state = next;
    _frameIndex = 0;
    notifyListeners();

    _stateResetTimer = Timer(_actionDuration, () {
      _state = PolypodAnimationState.idle;
      _frameIndex = 0;
      notifyListeners();
    });
  }

  void _startFrameTicker() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(_frameDuration, (_) {
      _frameIndex = (_frameIndex + 1) % framesPerRow;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _stateResetTimer?.cancel();
    _frameTimer?.cancel();
    super.dispose();
  }
}