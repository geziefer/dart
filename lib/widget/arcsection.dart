import 'package:flutter/material.dart';
import 'dart:math';

class ArcSection {
  final double startPercent;

  ArcSection({
    required this.startPercent,
  });
}

class ArcSectionPainter extends CustomPainter {
  final double radius;
  final List<ArcSection> arcSections;
  final double sliceAngle;
  final int sliceIndex;
  final double rotationAngle;

  ArcSectionPainter({
    required this.radius,
    required this.arcSections,
    required this.sliceAngle,
    required this.sliceIndex,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < arcSections.length; i++) {
      final arcSection = arcSections[i];
      final double innerRadius = radius * arcSection.startPercent;
      final double outerRadius = (i < arcSections.length - 1)
          ? radius * arcSections[i + 1].startPercent
          : radius;
      final double thickness = outerRadius - innerRadius;

      final List<List<Color>> alternatingColors = [
        [Colors.black, Colors.red, Colors.black, Colors.red],
        [Colors.white, Colors.green, Colors.white, Colors.green],
      ];
      final color = alternatingColors[sliceIndex % 2][i];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness;

      final Rect rect = Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: (innerRadius + outerRadius) / 2);
      final double startAngle = rotationAngle + sliceIndex * sliceAngle;
      final double sweepAngle = sliceAngle;

      final Path path = Path()..arcTo(rect, startAngle, sweepAngle, false);

      canvas.drawPath(path, paint);
    }

    // Draw center circle and arc with proper dartboard proportions
    final centerCirclePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final centerCircleRadius = radius * 0.1; // Inner bull (red)
    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        centerCircleRadius, centerCirclePaint);

    final centerArcPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          radius * 0.15; // Much thicker stroke for larger outer bull

    final centerArcRect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius:
            centerCircleRadius * 1.75); // Larger radius for bigger outer bull
    canvas.drawArc(centerArcRect, 0, 2 * pi, false, centerArcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  bool isPointInsideArcSection(Offset point, Size size, ArcSection arcSection,
      double innerRadius, double outerRadius) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double distanceFromCenter = (point - center).distance;
    final double angleInRadians =
        atan2(point.dy - center.dy, point.dx - center.dx);
    final double angleInDegrees = (angleInRadians * 180 / pi + 360) % 360;

    final double startAngle = (270.0 +
            rotationAngle * 180 / pi +
            sliceIndex * sliceAngle * 180 / pi) %
        360;
    final double endAngle = (startAngle + sliceAngle * 180 / pi) % 360;

    final bool isWithinAngle;
    if (startAngle < endAngle) {
      isWithinAngle =
          (angleInDegrees >= startAngle) && (angleInDegrees <= endAngle);
    } else {
      isWithinAngle =
          (angleInDegrees >= startAngle) || (angleInDegrees <= endAngle);
    }

    final bool isWithinRadius = (distanceFromCenter >= innerRadius) &&
        (distanceFromCenter <= outerRadius);

    return isWithinAngle && isWithinRadius;
  }

  bool isPointInsideCenterCircle(Offset point, Size size, double circleRadius) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double distanceFromCenter = (point - center).distance;
    return distanceFromCenter <= circleRadius;
  }

  bool isPointInsideCenterArc(
      Offset point, Size size, double innerRadius, double outerRadius) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double distanceFromCenter = (point - center).distance;
    return (distanceFromCenter >= innerRadius) &&
        (distanceFromCenter <= outerRadius);
  }
}
