import 'package:flutter/material.dart';
import 'base_app.dart';
import '../controllers/led_controller.dart';
import '../controllers/polypod_maintenance_controller.dart';
import '../controllers/bedroom_decoration_controller.dart';
import '../controllers/notification_controller.dart';
import '../config/screen_config.dart';
import 'mouth_animation.dart';
import '../utilities/decoration_mapper.dart';

/// Idle screen that displays when no app is active
class IdleApp extends BaseApp {
  const IdleApp({
    super.key,
    required this.maintenanceController,
    required this.notificationController,
    this.showBedroom = false,
    this.onBedroomToggleRequested,
  });

  final PolypodMaintenanceController maintenanceController;
  final NotificationController notificationController;
  final bool showBedroom;
  final VoidCallback? onBedroomToggleRequested;

  @override
  String get appName => 'Idle';

  @override
  State<IdleApp> createState() => _IdleAppState();
}

// this class maps all of the states from 'polypod_maintenance_controller.dart' to the appropriate mouth mood (AND LED COLORU) on the idle screen
// RILEY update these mappings as needed based on the final mood states
class _IdleAppState extends State<IdleApp> with TickerProviderStateMixin {
  final LEDController _ledController = LEDController();
  final BedroomDecorationController _decorationController =
      BedroomDecorationController();
  late PolypodMood _currentMood;
  late AnimationController _bedroomTransitionController;
  late Animation<double> _mouthOpenAmount;
  bool _decorationsReady = false;
  String? _lastNotificationId;

  @override
  void initState() {
    super.initState();
    _currentMood = widget.maintenanceController.mood;
    widget.maintenanceController.addListener(_handleMaintenanceChanged);
    widget.notificationController.addListener(_handleNotificationChanged);
    _syncLedColor(_currentMood);

    _bedroomTransitionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _mouthOpenAmount = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bedroomTransitionController, curve: Curves.easeInOut),
    );

    // If starting with bedroom shown, set animation to end state
    if (widget.showBedroom) {
      _bedroomTransitionController.forward(from: 1.0);
    }

    _initializeDecorations();
  }

  Future<void> _initializeDecorations() async {
    await _decorationController.initialize();
    if (!mounted) return;

    setState(() {
      _decorationsReady = _decorationController.isInitialized;
    });

    if (_decorationsReady) {
      _handleNotificationChanged();
    }
  }

  @override
  void didUpdateWidget(IdleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBedroom != widget.showBedroom) {
      if (widget.showBedroom) {
        _bedroomTransitionController.forward();
      } else {
        _bedroomTransitionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.maintenanceController.removeListener(_handleMaintenanceChanged);
    widget.notificationController.removeListener(_handleNotificationChanged);
    _bedroomTransitionController.dispose();
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

  Future<void> _handleNotificationChanged() async {
    if (!_decorationsReady) return;

    final notification = widget.notificationController.currentNotification;
    if (notification == null) return;

    // Only process if notification changed
    // Use a combination of timestamp and headline as unique ID since NotificationData doesn't have id field
    final notifId = '${notification.timestamp}_${notification.headline}';
    if (notifId == _lastNotificationId) return;
    _lastNotificationId = notifId;

    // Try to map notification to decoration
    final decorInfo = await DecorationMapper.mapNotificationToDecoration(
      notification.headline,
      notification.fromSource,
      notification.info,
    );

    if (decorInfo != null) {
      var wasAdded = false;
      setState(() {
        wasAdded = _decorationController.addDecoration(
          decorationType: 'team_jersey',
          teamName: decorInfo['team_name']!,
          genre: decorInfo['genre']!,
        );
      });

      if (!wasAdded) {
        debugPrint(
          'Decoration not added: no available zone or zone capacity reached.',
        );
      }
    } else {
      debugPrint(
        'No decoration mapping for notification: "${notification.headline}" '
        '(source: ${notification.fromSource}).',
      );
    }
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

  Widget _buildDecoratedBedroom() {
    final decorations = _decorationsReady
        ? _decorationController.getAllDecorations()
        : const <DecorationItem>[];
    final canvasWidth = ScreenConfig.topScreenWidth;
    final canvasHeight = ScreenConfig.topScreenHeight;
    const configCanvasWidth = 192.0;
    const configCanvasHeight = 144.0;
    final scaleX = canvasWidth / configCanvasWidth;
    final scaleY = canvasHeight / configCanvasHeight;

    return ClipRect(
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/br/bedroom.png',
              width: canvasWidth,
              height: canvasHeight,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
            for (final decoration in decorations)
              _buildDecorationWidget(
                decoration,
                scaleX: scaleX,
                scaleY: scaleY,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorationWidget(
    DecorationItem decoration, {
    required double scaleX,
    required double scaleY,
  }) {
    final zone = _decorationController.getZone(decoration.zoneId);
    if (zone == null) return const SizedBox.shrink();

    return Positioned(
      left: zone.pixelX * scaleX,
      top: zone.pixelY * scaleY,
      width: zone.pixelWidth * scaleX,
      height: zone.pixelHeight * scaleY,
      child: Opacity(
        opacity: 0.9, // Slight transparency for layering effect
        child: Image.asset(
          decoration.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bedroom background (appears when mouth is open)
          AnimatedBuilder(
            animation: _mouthOpenAmount,
            builder: (context, _) {
              return Opacity(
                opacity: _mouthOpenAmount.value.clamp(0.0, 1.0),
                child: _buildDecoratedBedroom(),
              );
            },
          ),
          // Mouth with expanding animation (clipped and scaled up)
          AnimatedBuilder(
            animation: _mouthOpenAmount,
            builder: (context, _) {
              final openAmount = _mouthOpenAmount.value;
              final scaleAmount = 1.0 + (openAmount * 15.0); // Scales to 16x when fully open

              return Opacity(
                opacity: 1.0 - (openAmount * 1.0), // Fully fades as it expands
                child: Transform.scale(
                  alignment: Alignment.center,
                  scale: scaleAmount,
                  child: MouthAnimation(
                    mood: _mouthMoodForPolypodMood(_currentMood),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
