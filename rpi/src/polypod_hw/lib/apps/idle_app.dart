import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../controllers/polypod_maintenance_controller.dart';

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
  Color _moodColor(PolypodMood mood) {
    return switch (mood) {
      PolypodMood.joyful => EarthyTheme.buttonColors[2],
      PolypodMood.content => EarthyTheme.buttonColors[1],
      PolypodMood.needy => EarthyTheme.buttonColors[0],
      PolypodMood.distressed => EarthyTheme.bark,
    };
  }

  Widget _metricBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EarthyTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (value / 100).clamp(0, 1),
            backgroundColor: EarthyTheme.surface,
            color: EarthyTheme.moss,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.maintenanceController,
      builder: (context, _) {
        final mood = widget.maintenanceController.mood;
        return Container(
          color: EarthyTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'web/icons/loader.gif',
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _moodColor(mood),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Mood: ${widget.maintenanceController.moodLabel}',
                  style: TextStyle(
                    color: EarthyTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.maintenanceController.moodMessage,
                style: TextStyle(color: EarthyTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 14),
              _metricBar('Hunger', widget.maintenanceController.hunger),
              const SizedBox(height: 8),
              _metricBar('Thirst', widget.maintenanceController.thirst),
              const SizedBox(height: 8),
              _metricBar('Affection', widget.maintenanceController.affection),
            ],
          ),
        );
      },
    );
  }
}
