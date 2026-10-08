/// Interface implemented by game controllers that support Scolia input.
///
/// A controller receives one completed [TurnResult] (the raw darts of a turn)
/// and interprets them according to its own game semantics, mutating its state
/// exactly as the equivalent numpad input would. This keeps a single shared
/// controller per game (no forking): the numpad path and the Scolia path
/// converge on identical state.
library;

import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/services/dart_target.dart';

abstract class ScoliaController {
  /// Apply a completed Scolia turn to the game state.
  void submitScoliaTurn(TurnResult turn);
}

/// Optional capability a [ScoliaController] may also implement to report, for
/// the throw-log analytics (A3), the intended aim points of the darts in the
/// most recently submitted turn (in dart order; an entry is null when the game
/// sets no target for that dart).
///
/// Kept separate from [ScoliaController] so controllers that don't define aim
/// points are unaffected. The Scolia dartboard checks `is AimTargetReporting`
/// after submitting a turn and logs the targets when available.
abstract class AimTargetReporting {
  List<DartTarget?> targetsForLastTurn();
}
