import 'package:flutter/material.dart';
import 'package:polypod_hw/config/theme_config.dart';
import '../config/screen_config.dart';
import '../apps/base_app.dart';
import '../controllers/clock_timer_controller.dart';

/// top screen widget that will display the mouth animations, notifications, and addtl info from bottom
class TopScreen extends StatelessWidget {
  final BaseApp currentApp;
  final ClockTimerController timerController;

  const TopScreen({
    Key? key,
    required this.currentApp,
    required this.timerController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.surface,
      width: ScreenConfig.topScreenWidth,
      height: ScreenConfig.topScreenHeight,
      child: Stack(
        children: [
          currentApp,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TopOverlayBar(
              items: [
                TimerOverlayItem(controller: timerController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopOverlayBar extends StatelessWidget {
  const TopOverlayBar({
    super.key,
    required this.items,
  });

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EarthyTheme.bark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      ),
    );
  }
}

class TimerOverlayItem extends StatelessWidget {
  const TimerOverlayItem({
    super.key,
    required this.controller,
  });

  final ClockTimerController controller;

  String _formatDuration(Duration value) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: EarthyTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_rounded, color: EarthyTheme.wheat, size: 18),
              const SizedBox(width: 8),
              Text(
                _formatDuration(controller.remaining),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: EarthyTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
