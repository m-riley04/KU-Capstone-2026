import 'dart:async';

import 'package:flutter/material.dart';
import 'base_app.dart';
import '../controllers/polypod_maintenance_controller.dart';
import 'mouth_animation.dart';

/// Idle screen that displays when no app is active
class IdleApp extends BaseApp {
  const IdleApp({
    super.key,
    required this.maintenanceController,
  });

  final PolypodMaintenanceController maintenanceController;

  @override
  String get appName => 'Idle';

  @override
  State<IdleApp> createState() => _IdleAppState();
}

class _IdleAppState extends State<IdleApp> {
  static const List<MouthMood> _debugMoods = [
    MouthMood.surprise,
    MouthMood.neutral,
    MouthMood.sad,
    MouthMood.evil,
  ];

  Timer? _debugMoodTimer;
  int _debugMoodIndex = 0;

  @override
  void initState() {
    super.initState();
    _debugMoodTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _debugMoodIndex = (_debugMoodIndex + 1) % _debugMoods.length;
      });
    });
  }

  @override
  void dispose() {
    _debugMoodTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: MouthAnimation(mood: _debugMoods[_debugMoodIndex]),
    );
  }
}
