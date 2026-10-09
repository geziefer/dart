import 'dart:math';

/// A generated training routine: an ordered list of game ids to play
/// back-to-back (one from each category).
class Routine {
  final List<String> gameIds;
  const Routine(this.gameIds);
}

/// Builds a routine by picking one random game from each of three fixed
/// categories (C1). This gives varied sessions while always covering scoring,
/// single-setup, and checkout practice.
class RoutineGenerator {
  /// Fixed categories, in play order, with their candidate game ids.
  static const List<List<String>> categories = [
    ['99x20', 'KB', '501m7'], // scoring
    ['PLANHIT', 'RTCS', 'CR'], // single setups
    ['C40', 'B27', 'DPath'], // checkout
  ];

  final Random _rng;

  RoutineGenerator({Random? rng}) : _rng = rng ?? Random();

  /// Generate a routine: one random game id from each category, in order.
  Routine generate() {
    return Routine([
      for (final options in categories) options[_rng.nextInt(options.length)],
    ]);
  }
}
