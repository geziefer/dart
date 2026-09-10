import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class FullCircle extends StatelessWidget {
  final DartboardController controller;
  final double radius;
  final List<ArcSection> arcSections;
  static const List<String> sliceIDs = [
    '1',
    '18',
    '4',
    '13',
    '6',
    '10',
    '15',
    '2',
    '17',
    '3',
    '19',
    '7',
    '16',
    '8',
    '11',
    '14',
    '9',
    '12',
    '5',
    '20'
  ];

  const FullCircle({
    super.key,
    required this.controller,
    required this.radius,
    required this.arcSections,
    this.highlightSector,
  });

  /// Optional sector to highlight (flash white), e.g. "T20", "S1", "D16",
  /// "25"/"SB" (outer bull), "Bull"/"DB" (inner bull), or "None"/"0"/miss
  /// (highlights a ring around the whole board). When null, nothing is
  /// highlighted (default; unchanged behaviour for existing callers).
  final String? highlightSector;

  @override
  Widget build(BuildContext context) {
    const int numberOfSlices = 20;
    const double sliceAngle = 360 / numberOfSlices;
    const double rotationAngle = (sliceAngle / 2) * pi / 180;

    return GestureDetector(
      onTapUp: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.globalToLocal(details.globalPosition);
        final size = renderBox.size;

        // Check center circle
        final double centerCircleRadius = radius * 0.1;
        if (ArcSectionPainter(
                radius: radius,
                arcSections: arcSections,
                sliceAngle: sliceAngle * pi / 180,
                sliceIndex: 0,
                rotationAngle: rotationAngle)
            .isPointInsideCenterCircle(position, size, centerCircleRadius)) {
          controller.pressDartboard('DB');
          return;
        }

        // Check center arc (outer bull) - much larger area
        final double innerArcRadius = radius * 0.1;
        final double outerArcRadius =
            radius * 0.25; // Significantly larger outer bull area
        if (ArcSectionPainter(
                radius: radius,
                arcSections: arcSections,
                sliceAngle: sliceAngle * pi / 180,
                sliceIndex: 0,
                rotationAngle: rotationAngle)
            .isPointInsideCenterArc(
                position, size, innerArcRadius, outerArcRadius)) {
          controller.pressDartboard('SB');
          return;
        }

        for (int sliceIndex = 0; sliceIndex < numberOfSlices; sliceIndex++) {
          final arcSectionsWithColors = List<ArcSection>.generate(
            arcSections.length,
            (index) => ArcSection(
              startPercent: arcSections[index].startPercent,
            ),
          );

          final painter = ArcSectionPainter(
            radius: radius,
            arcSections: arcSectionsWithColors,
            sliceAngle: sliceAngle * pi / 180,
            sliceIndex: sliceIndex,
            rotationAngle: rotationAngle,
          );

          for (int i = 0; i < arcSectionsWithColors.length; i++) {
            final arcSection = arcSectionsWithColors[i];
            final double innerRadius = radius * arcSection.startPercent;
            final double outerRadius = (i < arcSectionsWithColors.length - 1)
                ? radius * arcSectionsWithColors[i + 1].startPercent
                : radius;

            if (painter.isPointInsideArcSection(
                position, size, arcSection, innerRadius, outerRadius)) {
              String arcNo = sliceIDs.elementAt(sliceIndex);
              String arcField = switch (i) {
                0 => "S",
                1 => "T",
                2 => "S",
                3 => "D",
                _ => ""
              };
              controller.pressDartboard('$arcField$arcNo');
              break;
            }
          }
        }
      },
      child: CustomPaint(
        size: Size(radius * 2, radius * 2),
        painter: FullCirclePainter(
          radius: radius,
          arcSections: arcSections,
          sliceAngle: sliceAngle,
          rotationAngle: rotationAngle,
          sliceIDs: sliceIDs,
          highlightSector: highlightSector,
        ),
      ),
    );
  }
}

class FullCirclePainter extends CustomPainter {
  final double radius;
  final List<ArcSection> arcSections;
  final double sliceAngle;
  final double rotationAngle;
  final List<String> sliceIDs;
  final String? highlightSector;

  FullCirclePainter({
    required this.radius,
    required this.arcSections,
    required this.sliceAngle,
    required this.rotationAngle,
    required this.sliceIDs,
    this.highlightSector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int numberOfSlices = 20;

    for (int sliceIndex = 0; sliceIndex < numberOfSlices; sliceIndex++) {
      final arcSectionsWithColors = List<ArcSection>.generate(
        arcSections.length,
        (index) => ArcSection(
          startPercent: arcSections[index].startPercent,
        ),
      );

      final slicePainter = ArcSectionPainter(
        radius: radius,
        arcSections: arcSectionsWithColors,
        sliceAngle: sliceAngle * pi / 180,
        sliceIndex: sliceIndex,
        rotationAngle: rotationAngle,
      );

      slicePainter.paint(canvas, size);

      // Calculate angles for the arc section
      final double startAngle = (sliceIndex * (2 * pi / 20) - pi / 2) + pi / 20;
      const double sweepAngle = (2 * pi / 20);

      final center = Offset(size.width / 2, size.height / 2);

      // Calculate the position for the text
      final double labelAngle = startAngle + sweepAngle / 2;
      // Scale the label distance based on radius size
      final double labelRadius =
          radius + (radius * 0.08); // Dynamic spacing based on radius
      final double labelX = center.dx + labelRadius * cos(labelAngle);
      final double labelY = center.dy + labelRadius * sin(labelAngle);

      // Draw the text with size relative to radius
      final double fontSize =
          (radius / 10).clamp(20.0, 35.0); // Scale font size with radius
      final textSpan = TextSpan(
        text: sliceIDs[sliceIndex],
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              labelX - textPainter.width / 2, labelY - textPainter.height / 2));
    }

    // Draw center circle
    final centerCirclePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final centerCircleRadius = radius * 0.1; // Inner bull (red)
    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        centerCircleRadius, centerCirclePaint);

    // Draw center arc with larger outer bull
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

    // Optional highlight (white flash) of the hit sector.
    if (highlightSector != null) {
      _drawHighlight(canvas, size, highlightSector!);
    }
  }

  /// Paint a translucent white highlight over the given sector. Segment hits
  /// highlight the matching slice+ring; bull hits highlight the centre;
  /// a miss / "None" / "0" highlights a ring around the whole board.
  void _drawHighlight(Canvas canvas, Size size, String sector) {
    final center = Offset(size.width / 2, size.height / 2);
    final white = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Bull cases.
    if (sector == 'Bull' || sector == 'DB') {
      canvas.drawCircle(center, radius * 0.1, white);
      return;
    }
    if (sector == '25' || sector == 'SB') {
      final ring = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.15;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 0.1 * 1.75),
          0, 2 * pi, false, ring);
      return;
    }
    // Miss / 0 / None: highlight a ring around the whole board.
    if (sector == 'None' || sector == '0' || sector.isEmpty) {
      final ring = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06;
      canvas.drawCircle(center, radius * 1.05, ring);
      return;
    }

    // Segment: parse ring char + number, e.g. "T20", "S1", "D16" (also 's').
    final match = RegExp(r'^([SsDT])(\d{1,2})$').firstMatch(sector);
    if (match == null) return;
    final ringChar = match.group(1)!;
    final number = match.group(2)!;
    final sliceIndex = sliceIDs.indexOf(number);
    if (sliceIndex < 0) return;

    // Arc index mapping mirrors FullCircle's tap detection:
    // 0 -> S (outer single), 1 -> T, 2 -> S (inner single), 3 -> D.
    final int arcIndex = switch (ringChar) {
      'S' => 0, // outer single (either single band highlights acceptably)
      's' => 2, // inner single
      'T' => 1,
      'D' => 3,
      _ => -1,
    };
    if (arcIndex < 0) return;

    final double innerRadius = radius * arcSections[arcIndex].startPercent;
    final double outerRadius = (arcIndex < arcSections.length - 1)
        ? radius * arcSections[arcIndex + 1].startPercent
        : radius;

    final double sliceAngleRad = sliceAngle * pi / 180;
    final double startAngle = rotationAngle + sliceIndex * sliceAngleRad;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerRadius - innerRadius;
    final rect = Rect.fromCircle(
        center: center, radius: (innerRadius + outerRadius) / 2);
    canvas.drawArc(rect, startAngle, sliceAngleRad, false, highlight);
  }

  @override
  bool shouldRepaint(covariant FullCirclePainter oldDelegate) {
    return oldDelegate.highlightSector != highlightSector ||
        oldDelegate.radius != radius;
  }
}
