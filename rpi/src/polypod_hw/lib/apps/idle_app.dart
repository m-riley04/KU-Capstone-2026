import 'package:flutter/material.dart';
import 'base_app.dart';
import '../controllers/led_controller.dart';
import '../controllers/polypod_maintenance_controller.dart';
import 'mouth_animation.dart';

/// Idle screen that displays when no app is active
class IdleApp extends BaseApp {
  const IdleApp({super.key, required this.maintenanceController});

  final PolypodMaintenanceController maintenanceController;

  @override
  String get appName => 'Idle';

  @override
  State<IdleApp> createState() => _IdleAppState();
}

// this class maps all of the states from 'polypod_maintenance_controller.dart' to the appropriate mouth mood (AND LED COLORU) on the idle screen
// RILEY update these mappings as needed based on the final mood states
class _IdleAppState extends State<IdleApp> {
  final LEDController _ledController = LEDController();
  late PolypodMood _currentMood;

  @override
  void initState() {
    super.initState();
    _currentMood = widget.maintenanceController.mood;
    widget.maintenanceController.addListener(_handleMaintenanceChanged);
    _syncLedColor(_currentMood);
  }

  @override
  void dispose() {
    widget.maintenanceController.removeListener(_handleMaintenanceChanged);
    super.dispose();
  }

  void _handleMaintenanceChanged() {
    final nextMood = widget.maintenanceController.mood;
    if (nextMood == _currentMood) {
      return;
    }

    setState(() {
      _currentMood = nextMood;
    });
    _syncLedColor(nextMood);
  }
 // mood to animation
  MouthMood _mouthMoodForPolypodMood(PolypodMood mood) {
    return switch (mood) {
      PolypodMood.joyful => MouthMood.silly,
      PolypodMood.content => MouthMood.neutral,
      PolypodMood.needy => MouthMood.sad,
      PolypodMood.distressed => MouthMood.evil,
    };
  }

  // mood to LED color
  LEDColor _ledColorForPolypodMood(PolypodMood mood) {
    return switch (mood) {
      PolypodMood.joyful => LEDColor.green,
      PolypodMood.content => LEDColor.white,
      PolypodMood.needy => LEDColor.yellow,
      PolypodMood.distressed => LEDColor.red,
    };
  }

  Future<void> _syncLedColor(PolypodMood mood) async {
    await _ledController.setColor(_ledColorForPolypodMood(mood));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: MouthAnimation(mood: _mouthMoodForPolypodMood(_currentMood)),
    );
  }
}
