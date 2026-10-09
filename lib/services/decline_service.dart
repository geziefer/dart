/// Detects whether a game's recent results have gotten worse (C1 follow-up).
///
/// Compares the average of the most recent [window] results to the average of
/// the [window] results before them, oriented by whether higher is better. A
/// game is "declining" when the recent average is worse than the previous one
/// by more than a small [margin] (relative to the previous average, to stay
/// scale-independent across games).
class DeclineService {
  /// Number of results in each comparison window.
  final int window;

  /// Minimum relative change to count as a decline (e.g. 0.05 = 5% worse).
  final double margin;

  const DeclineService({this.window = 3, this.margin = 0.05});

  /// Whether [values] (oldest → newest) show a recent decline for a metric
  /// where higher-is-better is [higherIsBetter].
  ///
  /// Needs at least `window + 1` values; uses up to [window] on each side
  /// (recent vs. the immediately preceding block). Returns false when there's
  /// insufficient history or the change is within [margin].
  bool isDeclining(List<double> values, {required bool higherIsBetter}) {
    final n = values.length;
    if (n < window + 1) return false;

    final recent = values.sublist(n - window);
    final prevCount = (n - window).clamp(1, window);
    final prev = values.sublist(n - window - prevCount, n - window);

    final recentAvg = _avg(recent);
    final prevAvg = _avg(prev);
    if (prevAvg == 0) {
      // Can't take a relative change from zero; fall back to a direction check.
      return higherIsBetter ? recentAvg < prevAvg : recentAvg > prevAvg;
    }

    // Relative change of recent vs. previous.
    final change = (recentAvg - prevAvg) / prevAvg.abs();
    // Worse means down when higher-is-better, up when lower-is-better.
    return higherIsBetter ? change < -margin : change > margin;
  }

  static double _avg(List<double> xs) =>
      xs.reduce((a, b) => a + b) / xs.length;
}
