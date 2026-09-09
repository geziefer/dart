/// Interface implemented by game controllers that support Scolia input.
///
/// A controller receives one completed [TurnResult] (the raw darts of a turn)
/// and interprets them according to its own game semantics, mutating its state
/// exactly as the equivalent numpad input would. This keeps a single shared
/// controller per game (no forking): the numpad path and the Scolia path
/// converge on identical state.
library;

import 'package:dart/scolia/models/detected_throw.dart';

abstract class ScoliaController {
  /// Apply a completed Scolia turn to the game state.
  void submitScoliaTurn(TurnResult turn);
}
