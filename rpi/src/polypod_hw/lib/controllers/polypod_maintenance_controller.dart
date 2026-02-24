import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum PolypodMood {
  joyful,
  content,
  needy,
  distressed,
}

class PolypodMaintenanceController extends ChangeNotifier {
  PolypodMaintenanceController() {
    _decayTimer = Timer.periodic(_tickInterval, (_) => _tick());
  }

  static const Duration _tickInterval = Duration(seconds: 1);

  static const double _hungerDecayPerTick = 0.08;
  static const double _thirstDecayPerTick = 0.10;
  static const double _affectionDecayPerTick = 0.06;
  static const double _interactionBoostDecayPerTick = 0.18;

  double _hunger = 80;
  double _thirst = 80;
  double _affection = 80;
  double _interactionBoost = 0;

  Timer? _decayTimer;

  double get hunger => _hunger;
  double get thirst => _thirst;
  double get affection => _affection;

  double get wellnessScore {
    final weighted = (_hunger * 0.36) + (_thirst * 0.36) + (_affection * 0.28);
    return _clamp(weighted + _interactionBoost, 0, 100);
  }

  PolypodMood get mood {
    final score = wellnessScore;
    if (score >= 80) return PolypodMood.joyful;
    if (score >= 60) return PolypodMood.content;
    if (score >= 35) return PolypodMood.needy;
    return PolypodMood.distressed;
  }

  String get moodLabel {
    return switch (mood) {
      PolypodMood.joyful => 'Joyful',
      PolypodMood.content => 'Content',
      PolypodMood.needy => 'Needy',
      PolypodMood.distressed => 'Distressed',
    };
  }

  String get moodMessage {
    return switch (mood) {
      PolypodMood.joyful => 'Feeling great and thriving.',
      PolypodMood.content => 'Doing well. Keep it up.',
      PolypodMood.needy => 'Needs attention and care soon.',
      PolypodMood.distressed => 'Urgent care needed now.',
    };
  }

  void feed() {
    _hunger = _clamp(_hunger + 18, 0, 100);
    _affection = _clamp(_affection + 2, 0, 100);
    _interactionBoost = _clamp(_interactionBoost + 5, 0, 20);
    notifyListeners();
  }

  void water() {
    _thirst = _clamp(_thirst + 20, 0, 100);
    _interactionBoost = _clamp(_interactionBoost + 5, 0, 20);
    notifyListeners();
  }

  void pet() {
    _affection = _clamp(_affection + 16, 0, 100);
    _interactionBoost = _clamp(_interactionBoost + 7, 0, 20);
    notifyListeners();
  }

  void _tick() {
    final beforeMood = mood;

    _hunger = _clamp(_hunger - _hungerDecayPerTick, 0, 100);
    _thirst = _clamp(_thirst - _thirstDecayPerTick, 0, 100);
    _affection = _clamp(_affection - _affectionDecayPerTick, 0, 100);
    _interactionBoost = _clamp(_interactionBoost - _interactionBoostDecayPerTick, 0, 20);

    final afterMood = mood;
    if (beforeMood != afterMood || _interactionBoost > 0 || _hunger < 40 || _thirst < 40 || _affection < 40) {
      notifyListeners();
    }
  }

  double _clamp(double value, double minValue, double maxValue) {
    return max(minValue, min(value, maxValue));
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    super.dispose();
  }
}