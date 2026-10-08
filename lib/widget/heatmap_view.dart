import 'dart:math';

import 'package:flutter/material.dart';

import 'package:dart/services/throw_accuracy.dart';
import 'package:dart/services/throw_log_model.dart';

/// A dartboard overlay that plots actual dart landings (x/y) from the throw
/// log for one game, aggregated across sessions.
///
/// Pure Flutter [CustomPaint] (no image asset, no dependencies). Dots are
/// translucent so overlapping landings stack into a visual density/"heat"
/// without needing a KDE. Darts without coordinates are ignored by the caller
/// ([ThrowLogService.coordinatesForGame]); if none are provided a graceful
/// empty state is shown.
///
/// NOTE: the board y-axis orientation (screen-down vs board-up) has not yet
/// been validated against real hardware; [flipY] flips it in one place. Default
/// true maps board +y (up) to screen −y (up). Revisit once a physical Scolia
/// board is available.
class HeatmapView extends StatelessWidget {
  const HeatmapView({
    super.key,
    required this.darts,
    this.title,
    this.flipY = true,
  });

  /// The darts to plot. Only those with coordinates are drawn; others are
  /// skipped defensively.
  final List<LoggedDart> darts;

  /// Optional heading shown above the board.
  final String? title;

  /// When true, board +y (up) maps to screen −y. See class note.
  final bool flipY;

  int get _plottable => darts.where((d) => d.hasCoordinates).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
                color: Color.fromARGB(255, 215, 198, 132),
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _plottable == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Wurfdaten mit Koordinaten\n'
                      '(nur Scolia-Spiele am echten Board liefern Positionen).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              : Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = min(constraints.maxWidth,
                              constraints.maxHeight)
                          .clamp(0.0, double.infinity);
                      return SizedBox(
                        width: side,
                        height: side,
                        child: CustomPaint(
                          painter: _HeatmapPainter(darts: darts, flipY: flipY),
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (_plottable > 0) _metricsPanel(),
      ],
    );
  }

  /// Compact German accuracy panel shown under the board. Only lines with
  /// meaningful data are shown; a game with no intended targets (free-choice
  /// scoring) shows just the dart count.
  Widget _metricsPanel() {
    final acc = ThrowAccuracy.compute(darts);

    const label = TextStyle(color: Colors.white54, fontSize: 13);
    const value = TextStyle(
        color: Color.fromARGB(255, 215, 198, 132),
        fontSize: 14,
        fontWeight: FontWeight.bold);

    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l, style: label),
              Text(v, style: value),
            ],
          ),
        );

    final rows = <Widget>[
      row('Darts', '$_plottable'),
    ];

    if (acc.hasData && acc.meanDistanceMm != null) {
      rows.add(row('Ø Abstand zum Ziel', '${acc.meanDistanceMm!.round()} mm'));
      if (acc.stdDistanceMm != null) {
        rows.add(row('Streuung (σ)', '${acc.stdDistanceMm!.round()} mm'));
      }
      final mag = acc.biasMagnitudeMm;
      final clock = acc.biasClock;
      if (mag != null && mag >= 1 && clock != null) {
        rows.add(row('Versatz', '${mag.round()} mm Richtung $clock Uhr'));
      }
    }

    if (acc.outerSingleShare != null) {
      final outer = (acc.outerSingleShare! * 100).round();
      rows.add(row('Singles außen/innen', '$outer% / ${100 - outer}%'));
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({required this.darts, required this.flipY});

  final List<LoggedDart> darts;
  final bool flipY;

  /// Standard board dimensions in mm (radius from centre).
  static const double _innerBullMm = 6.35;
  static const double _outerBullMm = 15.9;
  static const double _trebleInnerMm = 99.0;
  static const double _trebleOuterMm = 107.0;
  static const double _doubleInnerMm = 162.0;
  static const double _doubleOuterMm = 170.0;

  /// The double-ring outer edge is drawn at this fraction of the draw radius,
  /// leaving room for the number labels and a thin "off-board" ring.
  static const double _boardFrac = 0.78;

  /// Number labels sit just outside the double ring.
  static const double _labelFrac = 0.86;

  /// Thin ring marking off-board/missed darts, outside the numbers. Stray darts
  /// are clamped to this radius so a wild miss sits on the ring, not flying off.
  static const double _offBoardFrac = 0.94;

  /// Board slice numbers in draw order, matching the input board
  /// (`FullCircle.sliceIDs`) so the heatmap geometry is identical to the board
  /// the darts were thrown at.
  static const List<String> _sliceIDs = [
    '1', '18', '4', '13', '6', '10', '15', '2', '17', '3', //
    '19', '7', '16', '8', '11', '14', '9', '12', '5', '20'
  ];

  /// Centre angle (radians, canvas convention: 0 = 3 o'clock, +ve clockwise)
  /// of slice [i], matching `FullCircle`'s label placement:
  ///   startAngle = i*18° − 90° + 9°, label at startAngle + 9°.
  double _sliceCenterAngle(int i) => (i * 18 - 90 + 18) * pi / 180;

  /// Map a board radius in mm to pixels (doubles outer edge → _boardFrac·r).
  double _mmToPx(double mm, double r) => mm / _doubleOuterMm * (_boardFrac * r);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    _drawBoard(canvas, center, r);
    _drawDarts(canvas, center, r);
  }

  void _drawBoard(Canvas canvas, Offset center, double r) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Reference rings (bull, treble band, double band) at true proportions.
    for (final mm in [
      _innerBullMm,
      _outerBullMm,
      _trebleInnerMm,
      _trebleOuterMm,
      _doubleInnerMm,
      _doubleOuterMm,
    ]) {
      canvas.drawCircle(center, _mmToPx(mm, r), line..color = Colors.white24);
    }

    // Thin "off-board" ring just outside the doubles (slim surround marker).
    canvas.drawCircle(
        center,
        _offBoardFrac * r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white24);

    // 20 slice dividers, from centre to the double outer edge. Wedge
    // boundaries sit halfway between adjacent number centres.
    final divider = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;
    final doubleOuterPx = _mmToPx(_doubleOuterMm, r);
    for (int i = 0; i < 20; i++) {
      final angle = _sliceCenterAngle(i) - (9 * pi / 180);
      final outer = center + Offset(cos(angle), sin(angle)) * doubleOuterPx;
      canvas.drawLine(center, outer, divider);
    }

    // Number labels just outside the double ring.
    for (int i = 0; i < 20; i++) {
      final angle = _sliceCenterAngle(i);
      final pos = center + Offset(cos(angle), sin(angle)) * (_labelFrac * r);
      final tp = TextPainter(
        text: TextSpan(
          text: _sliceIDs[i],
          style: TextStyle(
            color: Colors.white54,
            fontSize: (r / 14).clamp(10.0, 18.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawDarts(Canvas canvas, Offset center, double r) {
    final maxR = _offBoardFrac * r; // clamp strays to the off-board ring
    for (final d in darts) {
      if (!d.hasCoordinates) continue;
      double px = _mmToPx(d.x!, r);
      double py = (flipY ? -1 : 1) * _mmToPx(d.y!, r);
      // Clamp to the off-board ring so wild misses sit on the ring, not beyond.
      final dist = sqrt(px * px + py * py);
      if (dist > maxR && dist > 0) {
        final k = maxR / dist;
        px *= k;
        py *= k;
      }
      final paint = Paint()
        ..color = _colorFor(d).withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + Offset(px, py), max(3.0, r * 0.018), paint);
    }
  }

  /// Colour a dart by the ring it hit, for readability.
  Color _colorFor(LoggedDart d) {
    switch (d.ringEnum.name) {
      case 'innerBull':
      case 'outerBull':
        return Colors.redAccent;
      case 'triple':
        return Colors.greenAccent;
      case 'double':
        return Colors.lightBlueAccent;
      case 'single':
        return const Color.fromARGB(255, 215, 198, 132);
      default:
        // Miss / off-board.
        return Colors.deepOrangeAccent;
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.darts != darts || old.flipY != flipY;
}
