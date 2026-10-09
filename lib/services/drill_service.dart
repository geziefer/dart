import 'package:dart/services/dart_target.dart';
import 'package:dart/services/throw_log_model.dart';
import 'package:dart/services/weakness_service.dart';

/// A single focus suggestion for a weakness drill: a target to practice with a
/// human label and the measured hit rate that flagged it.
class DrillSuggestion {
  final DartTarget target;
  final String label; // e.g. 'T20', 'D16', 'Bull'
  final double hitRate; // 0..1

  const DrillSuggestion({
    required this.target,
    required this.label,
    required this.hitRate,
  });
}

/// Builds a focused practice drill from the player's weakest targets (B1).
///
/// The drill is the ordered list of the weakest targets (worst first) derived
/// from the throw log. It is dormant until real board data exists (the throw
/// log only fills from Scolia play) — with no data it yields an empty drill.
class DrillService {
  final WeaknessService _weakness;

  DrillService({WeaknessService? weakness})
      : _weakness = weakness ?? const WeaknessService();

  /// Produce up to [count] drill suggestions from [darts], worst first. Empty
  /// when there is insufficient data.
  List<DrillSuggestion> suggestDrill(List<LoggedDart> darts, {int count = 3}) {
    final worst = _weakness.weakest(darts, n: count);
    return worst
        .map((w) => DrillSuggestion(
              target: w.target,
              label: _label(w.target),
              hitRate: w.hitRate,
            ))
        .toList();
  }

  /// Short human label for a target, e.g. 'T20', 'D16', 'S5', 'Bull'.
  static String _label(DartTarget t) {
    switch (t.ring) {
      case TargetRing.innerBull:
      case TargetRing.outerBull:
        return 'Bull';
      case TargetRing.triple:
        return 'T${t.segment}';
      case TargetRing.double_:
        return 'D${t.segment}';
      case TargetRing.single:
      case TargetRing.innerSingle:
        return 'S${t.segment}';
    }
  }
}
