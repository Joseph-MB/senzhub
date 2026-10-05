import 'dart:math' as math;

import 'package:flutter/material.dart';

class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.values,
    this.color = const Color(0xFF23D18B),
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: CustomPaint(
            painter: _LineChartPainter(values: values, color: color),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('09:00', style: TextStyle(color: Color(0xFF8BA7A1), fontSize: 11)),
            Text('09:15', style: TextStyle(color: Color(0xFF8BA7A1), fontSize: 11)),
            Text('09:30', style: TextStyle(color: Color(0xFF8BA7A1), fontSize: 11)),
            Text('09:45', style: TextStyle(color: Color(0xFF8BA7A1), fontSize: 11)),
            Text('10:00', style: TextStyle(color: Color(0xFF8BA7A1), fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const warningThreshold = 3200.0;
    const dangerThreshold = 3700.0;

    final maxReading = math.max(
      values.reduce((a, b) => a > b ? a : b),
      dangerThreshold,
    );
    final minReading = math.min(
      values.reduce((a, b) => a < b ? a : b),
      2200.0,
    );
    final range = (maxReading - minReading).clamp(100.0, double.infinity);

    final chartLeft = 18.0;
    final chartRight = 12.0;
    final chartTop = 12.0;
    final chartBottom = 14.0;
    final chartWidth = size.width - chartLeft - chartRight;
    final chartHeight = size.height - chartTop - chartBottom;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final warningPaint = Paint()
      ..color = const Color(0xFFFFC857)
      ..strokeWidth = 1.5;
    final dangerPaint = Paint()
      ..color = const Color(0xFFFF5F6D)
      ..strokeWidth = 1.5;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final currentPaint = Paint()..color = Colors.white;

    for (var i = 0; i <= 3; i++) {
      final y = chartTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(chartLeft, y), Offset(size.width - chartRight, y), gridPaint);
    }

    final warningY = _yForValue(warningThreshold, minReading, range, chartTop, chartHeight, chartBottom);
    final dangerY = _yForValue(dangerThreshold, minReading, range, chartTop, chartHeight, chartBottom);

    canvas.drawLine(Offset(chartLeft, warningY), Offset(size.width - chartRight, warningY), warningPaint);
    canvas.drawLine(Offset(chartLeft, dangerY), Offset(size.width - chartRight, dangerY), dangerPaint);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = chartLeft + (chartWidth / (values.length - 1)) * i;
      final y = _yForValue(values[i], minReading, range, chartTop, chartHeight, chartBottom);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, (prev.dy + curr.dy) / 2);
    }
    final lastPoint = points.last;
    path.lineTo(lastPoint.dx, lastPoint.dy);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height - chartBottom)
      ..lineTo(points.first.dx, size.height - chartBottom)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final currentValue = values.last;
    final currentDot = Offset(lastPoint.dx, lastPoint.dy);
    canvas.drawCircle(currentDot, 5, currentPaint);
    canvas.drawCircle(currentDot, 10, Paint()..color = color.withValues(alpha: 0.18));

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Current ${currentValue.round()} ppm',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(lastPoint.dx - 26, math.max(4, lastPoint.dy - 18)));

    final warningLabel = TextPainter(
      text: const TextSpan(text: 'W 3200', style: TextStyle(color: Color(0xFFFFC857), fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dangerLabel = TextPainter(
      text: const TextSpan(text: 'D 3700', style: TextStyle(color: Color(0xFFFF5F6D), fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();

    warningLabel.paint(canvas, Offset(size.width - 58, warningY - 12));
    dangerLabel.paint(canvas, Offset(size.width - 58, dangerY - 12));
  }

  double _yForValue(
    double value,
    double minReading,
    double range,
    double chartTop,
    double chartHeight,
    double chartBottom,
  ) {
    final normalized = ((value - minReading) / range).clamp(0.0, 1.0);
    final y = chartTop + (chartHeight - (normalized * chartHeight));
    return y;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return values != oldDelegate.values || color != oldDelegate.color;
  }
}
