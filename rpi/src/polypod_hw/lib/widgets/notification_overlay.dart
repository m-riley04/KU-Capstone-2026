// RILEY ANDERSON
// 02/17/2026
// Notification display widget for top screen overlay

import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_models.dart';
import '../config/theme_config.dart';

/// Overlay widget that displays notifications on the top screen
class NotificationOverlay extends StatefulWidget {
  final NotificationController controller;

  const NotificationOverlay({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup scale animation from center
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceInOut,
    ));

    // Listen to notification changes
    widget.controller.addListener(_onNotificationChanged);
    
    // Animate in if we already have a notification
    if (widget.controller.hasNotification) {
      _animationController.forward();
    }
  }

  void _onNotificationChanged() {
    if (widget.controller.hasNotification) {
      _animationController.forward();
      // Auto-dismiss after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _animationController.reverse().then((_) {
            widget.controller.clearNotification();
          });
        }
      });
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNotificationChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _handleSeeMore() {
    // TODO: Implement QR code generation and display
    // For now, just keep the notification visible longer
    print('See more tapped for: ${widget.controller.currentNotification?.headline}');
  }

  void _handleDismiss() {
    _animationController.reverse().then((_) {
      widget.controller.clearNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (!widget.controller.hasNotification) {
          return const SizedBox.shrink();
        }

        return Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              children: [
                NotificationWidget(
                  notification: widget.controller.currentNotification!,
                  onSeeMore: _handleSeeMore,
                ),
                // Close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: EarthyTheme.wheat,
                      size: 28,
                    ),
                    onPressed: _handleDismiss,
                    style: IconButton.styleFrom(
                      backgroundColor: EarthyTheme.bark,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
