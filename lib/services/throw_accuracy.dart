import 'dart:math';

import 'package:dart/services/dart_target.dart';
import 'package:dart/services/throw_log_model.dart';

/// Accuracy metrics computed from a game's logged darts (A3).
///
/// Metrics are only meaningful for darts that both carry board coordinates
/// (Scolia) and have a known intended [DartTarget]. A dart whose landing is
/// `>= 2` sectors away from its target is treated as an intentional
/// setup/adjustment or a stray and excluded (misses carry no coordinates, so
/// they are excluded automatically).
class ThrowAccuracy {
  /// Darts with coordinates + a target that passed the exclusion rule.
  final int consideredDarts;

  /// Mean distance (mm) of each considered dart from its own intended target
  /// centre. The primary accuracy number ("how close to what I aimed at").
  /// Null when there are no considered darts.
  final double? meanDistanceMm;

  /// Standard deviation (mm) of those distances. Null when < 2 darts.
  final double? stdDistanceMm;

  /// Mean offset vector (dart − target) over considered darts, in mm (x right,
  /// y up). Indicates systematic directional bias. Null when none.
  final Point<double>? biasVector;

  /// Share of single-ring darts that landed in the outer (big) single, 0..1.
  /// Null when no single darts were thrown.
  final double? outerSingleShare;

  /// Number of single-ring darts considered for [outerSingleShare].
  final int singleCount;

  const ThrowAccuracy({
    required this.consideredDarts,
    required this.meanDistanceMm,
    required this.stdDistanceMm,
    required this.biasVector,
    required this.outerSingleShare,
    required this.singleCount,
  });

  /// Magnitude of the directional bias in mm, or null.
  double? get biasMagnitudeMm => biasVector == null
      ? null
      : sqrt(biasVector!.x * biasVector!.x + biasVector!.y * biasVector!.y);

  /// Clock-position label (1..12 o'clock) of the bias direction, or null when
  /// there is no meaningful bias (null vector or ~zero magnitude).
  int? get biasClock {
    final v = biasVector;
    if (v == null) return null;
    final mag = biasMagnitudeMm ?? 0;
    if (mag < 1e-6) return null;
    // atan2(x, y): 0 = straight up (12 o'clock), increasing clockwise.
    double deg = atan2(v.x, v.y) * 180 / pi;
    if (deg < 0) deg += 360;
    final clock = (deg / 30).round();
    return clock == 0 ? 12 : clock;
  }

  bool get hasData => consideredDarts > 0;

  /// Compute metrics from [darts]. Darts without coordinates or without a
  /// target are ignored; darts >= 2 sectors from their target are excluded.
  factory ThrowAccuracy.compute(List<LoggedDart> darts) {
    final distances = <double>[];
    double sumDx = 0, sumDy = 0;
    int considered = 0;
    int singles = 0, outerSingles = 0;

    for (final d in darts) {
      final target = d.target;
      if (target == null) continue;

      // Inner/outer single share uses the ring/flag only (no coordinates
      // needed): count singles aimed at a single target.
      if ((target.ring == TargetRing.single ||
              target.ring == TargetRing.innerSingle) &&
          d.ringEnum.name == 'single') {
        singles++;
        if (d.isOuterSingle) outerSingles++;
      }

      if (!d.hasCoordinates) continue;
      // Exclusion: a landing >= 2 wedges from the target wedge is intentional
      // or a stray, not an aiming error.
      if (target.sectorsAwayFrom(d.segment) >= 2) continue;

      final c = target.center;
      final dx = d.x! - c.x;
      final dy = d.y! - c.y;
      distances.add(sqrt(dx * dx + dy * dy));
      sumDx += dx;
      sumDy += dy;
      considered++;
    }

    double? mean;
    double? std;
    Point<double>? bias;
    if (considered > 0) {
      mean = distances.reduce((a, b) => a + b) / considered;
      bias = Point(sumDx / considered, sumDy / considered);
      if (considered >= 2) {
        final variance = distances
                .map((d) => (d - mean!) * (d - mean))
                .reduce((a, b) => a + b) /
            (considered - 1);
        std = sqrt(variance);
      }
    }

    return ThrowAccuracy(
      consideredDarts: considered,
      meanDistanceMm: mean,
      stdDistanceMm: std,
      biasVector: bias,
      outerSingleShare: singles > 0 ? outerSingles / singles : null,
      singleCount: singles,
    );
  }
}
