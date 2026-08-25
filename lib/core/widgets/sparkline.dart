import 'package:flutter/material.dart';

/// A minimal line chart for a short run of recent price ticks (in paise).
/// Draws nothing but a flat baseline until at least two points exist.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = 1.6,
  });

  final List<int> values;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  final List<int> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).toDouble();

    double yFor(int value) {
      if (range == 0) return size.height / 2;
      final normalized = (value - minValue) / range;
      return size.height - (normalized * size.height);
    }

    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(i * stepX, yFor(values[i]));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo((values.length - 1) * stepX, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(50), color.withAlpha(0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
