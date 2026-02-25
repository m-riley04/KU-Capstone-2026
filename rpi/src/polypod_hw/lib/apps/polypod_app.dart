import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../controllers/polypod_animation_controller.dart';
import '../services/audio_service.dart';
import '../widgets/control_button.dart';

class PolypodApp extends BaseApp {
  const PolypodApp({
    super.key,
    required this.controller,
    required this.onFeed,
    required this.onWater,
    required this.onPet,
    this.onFeedAudio,
    this.onWaterAudio,
    this.onPetAudio,
  });

  final PolypodAnimationController controller;
  final VoidCallback onFeed;
  final VoidCallback onWater;
  final VoidCallback onPet;
  final VoidCallback? onFeedAudio;
  final VoidCallback? onWaterAudio;
  final VoidCallback? onPetAudio;

  @override
  String get appName => 'Polypod';

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    print('[PolypodApp] buildBottomScreenContent called');
    final audioService = AudioService();
    return PolypodCareControls(
      onFeedPressed: () {
        print('[PolypodApp] Feed button pressed');
        (onFeedAudio ??
                () => audioService.playSound('assets/sounds/munching.mp3'))
            .call();
        controller.triggerFeed();
        onFeed();
      },
      onWaterPressed: () {
        print('[PolypodApp] Water button pressed');
        (onWaterAudio ??
                () => audioService.playSound('assets/sounds/slurp.mp3'))
            .call();
        controller.triggerWater();
        onWater();
      },
      onPetPressed: () {
        print('[PolypodApp] Pet button pressed');
        (onPetAudio ?? () => audioService.playSound('assets/sounds/purr.mp3'))
            .call();
        controller.triggerPet();
        onPet();
      },
    );
  }

  @override
  State<PolypodApp> createState() => _PolypodAppState();
}

class _PolypodAppState extends State<PolypodApp> {
  static const Map<PolypodAnimationState, List<String>> _stateSprites = {
    PolypodAnimationState.idle: [
      'web/sprites/isopod_emotes/neutral1.png',
      'web/sprites/isopod_emotes/neutral2.png',
    ],
    PolypodAnimationState.eating: [
      'web/sprites/isopod_emotes/eating1.png',
      'web/sprites/isopod_emotes/eating2.png',
    ],
    PolypodAnimationState.petting: [
      'web/sprites/isopod_emotes/love1.png',
      'web/sprites/isopod_emotes/love2.png',
    ],
    PolypodAnimationState.drinking: ['web/sprites/isopod_emotes/drinking1.png'],
  };

  final Map<PolypodAnimationState, int> _nextSpriteIndexByState = {};
  String? _currentSpritePath;
  PolypodAnimationState? _lastState;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerUpdate);
    _syncStateAndSprite(force: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    _syncStateAndSprite();
  }

  void _syncStateAndSprite({bool force = false}) {
    final currentState = widget.controller.state;
    if (force || _lastState != currentState) {
      _lastState = currentState;
      _currentSpritePath = _pickNextSpriteFor(currentState);
      if (mounted) {
        setState(() {});
      }
    }
  }

  String _pickNextSpriteFor(PolypodAnimationState state) {
    final sprites =
        _stateSprites[state] ?? _stateSprites[PolypodAnimationState.idle]!;
    final nextIndex = _nextSpriteIndexByState[state] ?? 0;
    final spritePath = sprites[nextIndex % sprites.length];
    _nextSpriteIndexByState[state] = (nextIndex + 1) % sprites.length;
    return spritePath;
  }

  String _currentSpriteFor(PolypodAnimationState state) {
    return _currentSpritePath ?? _pickNextSpriteFor(state);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: EarthyTheme.background,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  final state = widget.controller.state;
                  final spritePath = _currentSpriteFor(state);

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: EarthyTheme.surface,
                      child: Image.asset(
                        spritePath,
                        key: ValueKey('${state.name}-$spritePath'),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.bug_report_rounded,
                          color: EarthyTheme.textPrimary,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                final label = switch (widget.controller.state) {
                  PolypodAnimationState.idle => 'Idle',
                  PolypodAnimationState.eating => 'Eating',
                  PolypodAnimationState.petting => 'Pet',
                  PolypodAnimationState.drinking => 'Drinking',
                };
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: EarthyTheme.textPrimary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PolypodCareControls extends StatelessWidget {
  const PolypodCareControls({
    super.key,
    required this.onFeedPressed,
    required this.onWaterPressed,
    required this.onPetPressed,
  });

  final VoidCallback onFeedPressed;
  final VoidCallback onWaterPressed;
  final VoidCallback onPetPressed;

  // fallback icons below in case something cannot be loaded
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 72),
      color: EarthyTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: ControlButton(
              label: 'Feed',
              icon: Icons.restaurant_rounded,
              backgroundColor: EarthyTheme.buttonColors[0],
              onPressed: onFeedPressed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ControlButton(
              label: 'Water',
              icon: Icons.water_drop_rounded,
              backgroundColor: EarthyTheme.buttonColors[1],
              onPressed: onWaterPressed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ControlButton(
              label: 'Pet',
              icon: Icons.favorite_rounded,
              backgroundColor: EarthyTheme.buttonColors[2],
              onPressed: onPetPressed,
            ),
          ),
        ],
      ),
    );
  }
}
