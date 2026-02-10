import 'package:flutter/material.dart';

/// Reusable control button widget for the bottom screen
class ControlButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const ControlButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.backgroundColor ?? Colors.blue).withOpacity(0.7)
              : (widget.backgroundColor ?? Colors.blue),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 36,
              color: widget.textColor ?? Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.textColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
