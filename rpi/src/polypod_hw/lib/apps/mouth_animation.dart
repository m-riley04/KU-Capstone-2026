import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme_config.dart';

enum MouthMood { neutral, surprise, sad, evil, silly }

class MouthAnimation extends StatefulWidget {
  const MouthAnimation({super.key, this.mood = MouthMood.neutral});

  final MouthMood mood;

  @override
  State<MouthAnimation> createState() => _MouthAnimationState();
}

class _MouthAnimationState extends State<MouthAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _mouthController;
  late final AnimationController _moodController;
  late final Animation<double> _mouthOpen;
  late MouthMood _fromMood;
  late MouthMood _toMood;

  @override
  void initState() {
    super.initState();
    _mouthController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _moodController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
      value: 1.0,
    );

    _fromMood = widget.mood;
    _toMood = widget.mood;

    _mouthOpen = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant MouthAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _fromMood = _toMood;
      _toMood = widget.mood;
      _moodController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  _MouthStyle _styleFor(MouthMood mood, double openness) {
    return switch (mood) {
      MouthMood.neutral => _MouthStyle(
        scaleX: 0.90,
        scaleY: 0.20 + (openness * 0.95),
        tilt: (openness - 0.5) * 0.10,
        verticalShift: (1.0 - openness) * 14,
      ),
      MouthMood.surprise => _MouthStyle(
        scaleX: 0.45,
        scaleY: 2.0 + (openness * 0.5),
        tilt: 0,
        verticalShift: 0,
      ),
      MouthMood.sad => _MouthStyle(
        scaleX: 0.90,
        scaleY: 0.95 + (openness * 0.15),
        tilt: 0.03,
        verticalShift: 8,
      ),
      MouthMood.evil => _MouthStyle(
        scaleX: 0.90,
        scaleY: 0.42 + (openness * 0.55),
        tilt: -0.03,
        verticalShift: 8,
      ),
      MouthMood.silly => _MouthStyle(
        scaleX: 0.95,
        scaleY: 0.88 + (openness * 0.15),
        tilt: 0.02,
        verticalShift: 7,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EarthyTheme.polypod,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mouthOpen, _moodController]),
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          final mouthWidth = size.width * 0.78;
          final mouthHeight = size.height * 0.20;
          final openness = _mouthOpen.value;
          final transitionT = Curves.easeInOutCubic.transform(
            _moodController.value,
          );

          final fromStyle = _styleFor(_fromMood, openness);
          final toStyle = _styleFor(_toMood, openness);
          final activeStyle = _MouthStyle.lerp(fromStyle, toStyle, transitionT);

          return Center(
            child: Transform.translate(
              offset: Offset(0, activeStyle.verticalShift),
              child: Transform.rotate(
                angle: activeStyle.tilt,
                child: Transform.scale(
                  alignment: Alignment.center,
                  scaleX: activeStyle.scaleX,
                  scaleY: activeStyle.scaleY,
                  child: CustomPaint(
                    size: Size(mouthWidth, mouthHeight),
                    painter: MouthPainter(
                      fromMood: _fromMood,
                      toMood: _toMood,
                      transitionT: transitionT,
                      openness: openness,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MouthPainter extends CustomPainter {
  const MouthPainter({
    required this.fromMood,
    required this.toMood,
    required this.transitionT,
    required this.openness,
  });

  final MouthMood fromMood;
  final MouthMood toMood;
  final double transitionT;
  final double openness;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = Color.lerp(
      Colors.pink.shade300,
      Colors.pink.shade500,
      0.5,
    )!;

    final shapeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    final fromPath = _pathForMood(fromMood, shapeRect, size);
    final toPath = _pathForMood(toMood, shapeRect, size);

    if (fromMood == toMood) {
      canvas.drawPath(
        fromPath,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill,
      );
    } else {
      final fromAlpha = (1.0 - transitionT).clamp(0.0, 1.0);
      final toAlpha = transitionT.clamp(0.0, 1.0);

      canvas.drawPath(
        fromPath,
        Paint()
          ..color = baseColor.withValues(alpha: fromAlpha)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        toPath,
        Paint()
          ..color = baseColor.withValues(alpha: toAlpha)
          ..style = PaintingStyle.fill,
      );
    }

    final evilStrength = _moodStrength(MouthMood.evil);
    if (evilStrength > 0) {
      final fangLength = size.height * 0.45;
      final fangWidth = size.width * 0.02;
      final topY = size.height * 0.5;

      final leftCenterX = size.width * 0.4;
      final rightCenterX = size.width * 0.6;

      final leftFang = Path()
        ..moveTo(leftCenterX - fangWidth, topY)
        ..lineTo(leftCenterX + fangWidth, topY)
        ..lineTo(leftCenterX, topY + fangLength)
        ..close();

      final rightFang = Path()
        ..moveTo(rightCenterX - fangWidth, topY)
        ..lineTo(rightCenterX + fangWidth, topY)
        ..lineTo(rightCenterX, topY + fangLength)
        ..close();

      final fangPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: (0.35 + (0.65 * evilStrength)).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.clipPath(Path.combine(PathOperation.union, fromPath, toPath));
      canvas.drawPath(leftFang, fangPaint);
      canvas.drawPath(rightFang, fangPaint);
      canvas.restore();
    }

    final sillyStrength = _moodStrength(MouthMood.silly);
    if (sillyStrength > 0) {
      final tongueTopY = size.height * 0.50;
      final tongueLength = size.height * (0.75 + (0.2 * openness));
      final tongueHalfWidth = size.width * 0.09;
      final tongueCenterX = size.width * 0.6;

      final tongueLeft = tongueCenterX - tongueHalfWidth;
      final tongueRight = tongueCenterX + tongueHalfWidth;
      final tongueBottom = tongueTopY + tongueLength;
      final tongueTipRadiusY = tongueLength * 0.20;

      final tonguePath = Path()
        ..moveTo(tongueLeft, tongueTopY)
        ..lineTo(tongueRight, tongueTopY)
        ..lineTo(tongueRight, tongueBottom - tongueTipRadiusY)
        ..quadraticBezierTo(
          tongueRight,
          tongueBottom,
          tongueCenterX,
          tongueBottom,
        )
        ..quadraticBezierTo(
          tongueLeft,
          tongueBottom,
          tongueLeft,
          tongueBottom - tongueTipRadiusY,
        )
        ..lineTo(tongueLeft, tongueTopY)
        ..close();

      final tongueoutlinePaint = Paint()
        ..color = const Color.fromARGB(255, 87, 14, 14).withValues(
          alpha: (0.12 + (0.3 * sillyStrength)).clamp(0.0, 1.0),
        )
        ..strokeWidth = size.width * 0.007
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final tonguePaint = Paint()
        ..color = Colors.red.shade600.withValues(
          alpha: (0.2 + (0.8 * sillyStrength)).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(tonguePath, tonguePaint);

      canvas.drawPath(tonguePath, tongueoutlinePaint);

      final groovePaint = Paint()
        ..color = Colors.red.shade900.withValues(
          alpha: (0.12 + (0.3 * sillyStrength)).clamp(0.0, 1.0),
        )
        ..strokeWidth = size.width * 0.007
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(tongueCenterX, tongueTopY + (tongueLength * 0.18)),
        Offset(tongueCenterX, tongueTopY + (tongueLength * 0.86)),
        groovePaint,
      );
    }
  }

  Path _pathForMood(MouthMood mood, Rect shapeRect, Size size) {
    return switch (mood) {
      MouthMood.neutral =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..addArc(shapeRect, 0, math.pi)
          ..close(),
      MouthMood.surprise => Path()..addOval(shapeRect),
      MouthMood.sad =>
        Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..addArc(shapeRect, math.pi, math.pi)
          ..close(),
      MouthMood.evil =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..addArc(shapeRect, 0, math.pi)
          ..close(),
      MouthMood.silly =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..addArc(shapeRect, 0, math.pi)
          ..close(),
    };
  }

  double _moodStrength(MouthMood mood) {
    if (fromMood == toMood) {
      return fromMood == mood ? 1.0 : 0.0;
    }
    if (mood == fromMood) {
      return (1.0 - transitionT).clamp(0.0, 1.0);
    }
    if (mood == toMood) {
      return transitionT.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  @override
  bool shouldRepaint(covariant MouthPainter oldDelegate) {
    return oldDelegate.fromMood != fromMood ||
        oldDelegate.toMood != toMood ||
        oldDelegate.transitionT != transitionT ||
        oldDelegate.openness != openness;
  }
}

class _MouthStyle {
  const _MouthStyle({
    required this.scaleX,
    required this.scaleY,
    required this.tilt,
    required this.verticalShift,
  });

  final double scaleX;
  final double scaleY;
  final double tilt;
  final double verticalShift;

  static _MouthStyle lerp(_MouthStyle a, _MouthStyle b, double t) {
    return _MouthStyle(
      scaleX: a.scaleX + ((b.scaleX - a.scaleX) * t),
      scaleY: a.scaleY + ((b.scaleY - a.scaleY) * t),
      tilt: a.tilt + ((b.tilt - a.tilt) * t),
      verticalShift:
          a.verticalShift + ((b.verticalShift - a.verticalShift) * t),
    );
  }
}
