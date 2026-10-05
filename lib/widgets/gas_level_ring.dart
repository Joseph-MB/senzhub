import 'dart:math' as math;

import 'package:flutter/material.dart';

class GasLevelRing extends StatelessWidget {
  const GasLevelRing({
    super.key,
    required this.value,
    required this.warningThreshold,
    required this.dangerThreshold,
    this.size = 180,
  });

  final int value;
  final int warningThreshold;
  final int dangerThreshold;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, dangerThreshold + 800);
    final safeProgress = (clampedValue / (dangerThreshold + 800)).clamp(0.0, 1.0);
    final warningProgress = (warningThreshold / (dangerThreshold + 800)).clamp(0.0, 1.0);
    final dangerProgress = (dangerThreshold / (dangerThreshold + 800)).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GasLevelRingPainter(
          value: safeProgress,
          warningProgress: warningProgress,
          dangerProgress: dangerProgress,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PPM',
                style: TextStyle(
                  color: Color(0xFF8BA7A1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GasLevelRingPainter extends CustomPainter {
  const _GasLevelRingPainter({
    required this.value,
    required this.warningProgress,
    required this.dangerProgress,
  });

  final double value;
  final double warningProgress;
  final double dangerProgress;

  @override
  void paint(Canvas canvas, Size size) {
    const trackColor = Color(0xFF1B2C26);
    final basePaint = Paint()
      ..color = trackColor
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final safePaint = Paint()
      ..color = const Color(0xFF23D18B)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final warningPaint = Paint()
      ..color = const Color(0xFFFFC857)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dangerPaint = Paint()
      ..color = const Color(0xFFFF5F6D)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 12);
    final startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2;

    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);
    canvas.drawArc(rect, startAngle, sweepAngle * value, false, safePaint);

    final warningAngle = (warningProgress * math.pi * 2) - (math.pi / 2);
    final dangerAngle = (dangerProgress * math.pi * 2) - (math.pi / 2);

    final warningPoint = Offset(
      size.width / 2 + math.cos(warningAngle) * (size.width / 2 - 8),
      size.height / 2 + math.sin(warningAngle) * (size.height / 2 - 8),
    );
    final dangerPoint = Offset(
      size.width / 2 + math.cos(dangerAngle) * (size.width / 2 - 8),
      size.height / 2 + math.sin(dangerAngle) * (size.height / 2 - 8),
    );

    canvas.drawCircle(warningPoint, 5, warningPaint);
    canvas.drawCircle(dangerPoint, 5, dangerPaint);
  }

  @override
  bool shouldRepaint(covariant _GasLevelRingPainter oldDelegate) {
    return value != oldDelegate.value ||
        warningProgress != oldDelegate.warningProgress ||
        dangerProgress != oldDelegate.dangerProgress;
  }
}
