import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../controllers/clock_timer_controller.dart';

class ClockApp extends BaseApp {
  ClockApp({super.key, required this.controller});

  final ClockTimerController controller;

  @override
  String get appName => 'Clock';

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    return HorizontalWheelList(
      onSelectionChanged: controller.updateSelection,
      onStart: controller.start,
      onPause: controller.pause,
      onReset: controller.reset,
    );
  }

  @override
  State<ClockApp> createState() => _ClockAppState();
}

class HorizontalWheelList extends StatefulWidget {
  const HorizontalWheelList({
    super.key,
    this.onSelectionChanged,
    this.onStart,
    this.onPause,
    this.onReset,
  });

  final void Function(Duration value)? onSelectionChanged;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onReset;

  @override
  State<HorizontalWheelList> createState() => _HorizontalWheelListState();
}

class _HorizontalWheelListState extends State<HorizontalWheelList> {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  void _notifySelection() {
    widget.onSelectionChanged?.call(
      Duration(hours: _hours, minutes: _minutes, seconds: _seconds),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Helper to create a single scrollable wheel
    Widget buildWheel(String name, int choices, ValueChanged<int> onChanged) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 50, // Height of each item
                perspective: 0.005, // 3D effect strength
                diameterRatio: 1.5, // Cylinder diameter
                physics: const FixedExtentScrollPhysics(), // Snaps to items
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: choices,
                  builder: (context, index) {
                    return Card(
                      color: EarthyTheme.buttonColors[index % 5],
                      child: Center(
                        child: Text(index.toString().padLeft(2, '0')),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 200, // explicit height
          child: Row(
            children: [
              buildWheel('Hour', 12, (value) {
                setState(() {
                  _hours = value;
                });
                _notifySelection();
              }),
              buildWheel('Minute', 60, (value) {
                setState(() {
                  _minutes = value;
                });
                _notifySelection();
              }),
              buildWheel('Second', 60, (value) {
                setState(() {
                  _seconds = value;
                });
                _notifySelection();
              }),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: EarthyTheme.forestGreen,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: widget.onStart,
                      color: EarthyTheme.wheat,
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause_circle_filled_rounded),
                      onPressed: widget.onPause,
                      color: EarthyTheme.wheat,
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: widget.onReset,
                      color: EarthyTheme.wheat,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockAppState extends State<ClockApp> {
  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  String _formatDuration(Duration value) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_rounded, size: 60, color: EarthyTheme.wheat),
            const SizedBox(height: 20),
            Text(
              _formatDuration(widget.controller.remaining),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: EarthyTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.controller.isRunning ? 'Running' : 'Ready',
              style: TextStyle(fontSize: 18, color: EarthyTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
