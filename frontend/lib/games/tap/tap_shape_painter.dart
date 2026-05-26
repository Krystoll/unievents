import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tap_game_logic.dart';

class TapShapePainter extends CustomPainter {
  TapShapePainter({required this.shape, required this.color});

  final TargetShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final padding = size.shortestSide * 0.08;

    switch (shape) {
      case TargetShape.circle:
        canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2, paint);
      case TargetShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(size.shortestSide * 0.2),
          ),
          paint,
        );
      case TargetShape.triangle:
        final path = Path()
          ..moveTo(size.width / 2, padding)
          ..lineTo(size.width - padding, size.height - padding)
          ..lineTo(padding, size.height - padding)
          ..close();
        canvas.drawPath(path, paint);
      case TargetShape.star:
        canvas.drawPath(_starPath(size), paint);
      case TargetShape.house:
        final baseTop = size.height * 0.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, baseTop, size.width * 0.6, size.height * 0.4),
            Radius.circular(size.shortestSide * 0.1),
          ),
          paint,
        );
        final roof = Path()
          ..moveTo(size.width / 2, padding)
          ..lineTo(size.width - padding, baseTop)
          ..lineTo(padding, baseTop)
          ..close();
        canvas.drawPath(roof, paint);
    }
  }

  Path _starPath(Size size) {
    final outerRadius = size.shortestSide / 2.2;
    final innerRadius = outerRadius * 0.5;
    final center = size.center(Offset.zero);
    final path = Path()..moveTo(center.dx, center.dy - outerRadius);
    for (var i = 1; i < 10; i++) {
      final angle = math.pi / 5 * i - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      path.lineTo(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant TapShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}
