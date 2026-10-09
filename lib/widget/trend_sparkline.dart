import 'package:flutter/material.dart';

/// A compact sparkline of a game's recent result values (B2 trend view).
///
/// Plots [values] (oldest → newest) as a polyline scaled to the widget bounds.
/// [higherIsBetter] only tints the line (green when the latest value beats the
/// first, red when worse); it does not change the plot. Shows a dash when there
/// are fewer than two points.
class TrendSparkline extends StatelessWidget {
  const TrendSparkline({
    super.key,
    required this.values,
    this.higherIsBetter = true,
    this.width = 120,
    this.height = 28,
  });

  final List<double> values;
  final bool higherIsBetter;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Text('—', style: TextStyle(color: Colors.white38)),
        ),
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(values, higherIsBetter),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.higherIsBetter);

  final List<double> values;
  final bool higherIsBetter;

  @override
  void paint(Canvas canvas, Size size) {
    double minV = values.first, maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final x = dx * i;
      // Invert y (canvas y grows downward) so higher values sit higher.
      final norm = (values[i] - minV) / range;
      final y = size.height - norm * size.height;
      return Offset(x, y);
    }

    final improved = higherIsBetter
        ? values.last >= values.first
        : values.last <= values.first;
    final line = Paint()
      ..color = improved ? Colors.greenAccent : Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(path, line);

    // Emphasise the latest point.
    final last = pointAt(values.length - 1);
    canvas.drawCircle(
        last, 2.5, Paint()..color = improved ? Colors.greenAccent : Colors.redAccent);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.higherIsBetter != higherIsBetter;
}
