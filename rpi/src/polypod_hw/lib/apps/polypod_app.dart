import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../controllers/polypod_animation_controller.dart';
import '../widgets/control_button.dart';

class PolypodApp extends BaseApp {
  const PolypodApp({
    super.key,
    required this.controller,
    required this.onFeed,
    required this.onWater,
    required this.onPet,
  });

  final PolypodAnimationController controller;
  final VoidCallback onFeed;
  final VoidCallback onWater;
  final VoidCallback onPet;

  @override
  String get appName => 'Polypod';

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    return PolypodCareControls(
      onFeedPressed: () {
        controller.triggerFeed();
        onFeed();
      },
      onWaterPressed: () {
        controller.triggerWater();
        onWater();
      },
      onPetPressed: () {
        controller.triggerPet();
        onPet();
      },
    );
  }

  @override
  State<PolypodApp> createState() => _PolypodAppState();
}

class _PolypodAppState extends State<PolypodApp>
    with SingleTickerProviderStateMixin {
  static const Map<PolypodAnimationState, String> _animationUrls = {
    PolypodAnimationState.idle:
        'https://fonts.gstatic.com/s/e/notoemoji/latest/1f610/lottie.json',
    PolypodAnimationState.eating:
        'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60b/lottie.json',
    PolypodAnimationState.petting:
        'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60d/lottie.json',
    PolypodAnimationState.drinking:
        'https://fonts.gstatic.com/s/e/notoemoji/latest/1f924/lottie.json',
  };

  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
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
                  final animationUrl =
                      _animationUrls[state] ?? _animationUrls[PolypodAnimationState.idle]!;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: EarthyTheme.surface,
                      child: Lottie.network(
                        animationUrl,
                        key: ValueKey(state),
                        controller: _lottieController,
                        fit: BoxFit.contain,
                        onLoaded: (composition) {
                          _lottieController
                            ..duration = composition.duration
                            ..repeat();
                        },
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