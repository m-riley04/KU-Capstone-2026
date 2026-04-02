import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../controllers/clock_timer_controller.dart';

class ClockApp extends BaseApp {
  const ClockApp({super.key, required this.controller});

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
    /// Builds a single column with an up arrow, the current value, and a
    /// down arrow.  [maxValue] is exclusive (e.g. 12 for hours, 60 for
    /// minutes/seconds).
    Widget buildPicker(
      String label,
      int value,
      int maxValue,
      ValueChanged<int> onChanged,
    ) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            IconButton(
              iconSize: 58,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
              icon: Icon(Icons.keyboard_arrow_up_rounded,
                  color: EarthyTheme.wheat),
              onPressed: () {
                onChanged((value + 1) % maxValue);
              },
            ),
            Container(
              width: 50,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EarthyTheme.forestGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: EarthyTheme.wheat,
                ),
              ),
            ),
            IconButton(
              iconSize: 58,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: EarthyTheme.wheat),
              onPressed: () {
                onChanged((value - 1 + maxValue) % maxValue);
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Align(
        alignment: const Alignment(0, -0.5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              buildPicker('Hour', _hours, 12, (v) {
                setState(() => _hours = v);
                _notifySelection();
              }),
              buildPicker('Min', _minutes, 60, (v) {
                setState(() => _minutes = v);
                _notifySelection();
              }),
              buildPicker('Sec', _seconds, 60, (v) {
                setState(() => _seconds = v);
                _notifySelection();
              }),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
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
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        ),
                      onPressed: widget.onStart,
                      color: EarthyTheme.wheat,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.pause_circle_filled_rounded,
                        size: 40,
                        ),
                      onPressed: widget.onPause,
                      color: EarthyTheme.wheat,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.restore,
                        size: 40,
                        ),
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
