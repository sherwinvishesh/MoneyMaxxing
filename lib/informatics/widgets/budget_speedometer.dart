// lib/informatics/widgets/budget_speedometer.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BudgetSpeedometer extends StatelessWidget {
  final double spent;
  final double total;
  final double size;

  const BudgetSpeedometer({
    super.key,
    required this.spent,
    required this.total,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage spent (capped at 100%)
    final percentage = (spent / total).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size / 2, // Remove the extra height that was causing overflow
      child: CustomPaint(
        size: Size(size, size / 2),
        painter: SpeedometerPainter(
          percentage: percentage,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.red,
        ),
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color foregroundColor;

  SpeedometerPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Paint for the arc background (remaining budget)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Paint for the arc foreground (spent)
    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Draw background arc (180 degrees / pi radians)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // Draw foreground arc (based on percentage)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi,
      percentage * math.pi,
      false,
      foregroundPaint,
    );

    // No needle, no text labels, just the colored arcs
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
