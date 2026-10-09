import 'dart:math';

import 'package:dart/services/dart_target.dart';
import 'package:dart/services/throw_log_model.dart';

/// Accuracy summary for one intended target across logged darts (B1).
class TargetWeakness {
  final DartTarget target;

  /// Number of darts aimed at this target (that were considered — i.e. landed
  /// within range, not excluded as intentional strays).
  final int attempts;

  /// Darts that actually hit the intended ring+segment.
  final int hits;

  /// Mean landing distance (mm) to the target centre over attempts with
  /// coordinates, or null when none carried coordinates.
  final double? meanDistanceMm;

  const TargetWeakness({
    required this.target,
    required this.attempts,
    required this.hits,
    required this.meanDistanceMm,
  });

  /// Hit rate 0..1.
  double get hitRate => attempts == 0 ? 0 : hits / attempts;
}

/// Ranks a player's weakest targets from the throw log so a focused drill can
/// be built (B1). Pure computation over [LoggedDart]s; only darts that carry a
/// known target are considered. A dart `>= 2` sectors from its target is
/// treated as an intentional/stray throw and excluded (matching the accuracy
/// metrics), and misses carry no coordinates.
class WeaknessService {
  /// Minimum attempts a target needs before it can be ranked (avoids calling a
  /// target "weak" from one or two throws).
  final int minAttempts;

  const WeaknessService({this.minAttempts = 5});

  /// Group [darts] by intended target and summarise accuracy per target.
  List<TargetWeakness> summarise(List<LoggedDart> darts) {
    // Key targets by (segment, ring) so repeated aims aggregate.
    final byKey = <String, List<LoggedDart>>{};
    for (final d in darts) {
      final t = d.target;
      if (t == null) continue;
      if (t.sectorsAwayFrom(d.segment) >= 2) continue; // stray/intentional
      byKey.putIfAbsent('${t.segment}:${t.ringName}', () => []).add(d);
    }

    final out = <TargetWeakness>[];
    byKey.forEach((_, group) {
      final target = group.first.target!;
      int hits = 0;
      final distances = <double>[];
      for (final d in group) {
        if (_isHit(d, target)) hits++;
        if (d.hasCoordinates) {
          final c = target.center;
          distances.add(sqrt(
              (d.x! - c.x) * (d.x! - c.x) + (d.y! - c.y) * (d.y! - c.y)));
        }
      }
      out.add(TargetWeakness(
        target: target,
        attempts: group.length,
        hits: hits,
        meanDistanceMm: distances.isEmpty
            ? null
            : distances.reduce((a, b) => a + b) / distances.length,
      ));
    });
    return out;
  }

  /// The weakest [n] targets with at least [minAttempts] attempts, worst first.
  /// "Worst" = lowest hit rate, tie-broken by larger mean distance.
  List<TargetWeakness> weakest(List<LoggedDart> darts, {int n = 3}) {
    final ranked = summarise(darts)
        .where((w) => w.attempts >= minAttempts)
        .toList()
      ..sort((a, b) {
        final r = a.hitRate.compareTo(b.hitRate);
        if (r != 0) return r;
        final da = a.meanDistanceMm ?? 0;
        final db = b.meanDistanceMm ?? 0;
        return db.compareTo(da); // larger distance = worse
      });
    return ranked.take(n).toList();
  }

  bool _isHit(LoggedDart d, DartTarget t) {
    final ring = d.ringEnum.name;
    switch (t.ring) {
      case TargetRing.innerBull:
      case TargetRing.outerBull:
        // Aiming at the bull: either bull ring counts as a hit.
        return ring == 'innerBull' || ring == 'outerBull';
      case TargetRing.triple:
        return ring == 'triple' && d.segment == t.segment;
      case TargetRing.double_:
        return ring == 'double' && d.segment == t.segment;
      case TargetRing.single:
      case TargetRing.innerSingle:
        return ring == 'single' && d.segment == t.segment;
    }
  }
}
