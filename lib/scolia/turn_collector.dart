/// Aggregates individual detected darts into completed turns.
///
/// Scolia reports each dart individually via THROW_DETECTED, and signals the
/// end of a turn via TAKEOUT_FINISHED (§4.3.6). This collector buffers darts
/// and emits a [TurnResult] when the turn closes.
///
/// Turn-closing rules (per the plan / spec):
/// - A real takeout ([onTakeoutFinished] with `falseTakeout == false`) closes
///   the current turn and emits its darts (even if fewer than 3 — e.g. a
///   checkout or bust).
/// - A `falseTakeout` is ignored (the user stepped into view but did not remove
///   darts).
/// - Optionally, reaching [maxDartsPerTurn] darts auto-closes the turn. This is
///   a safety net; the primary boundary is the takeout event.
/// - Darts are ignored while the board is not in the Throw phase.
/// - [reset] clears any buffered darts (call on game entry so darts already on
///   the board when connecting don't leak into the first turn).
library;

import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/board_state.dart';

class TurnCollector {
  TurnCollector({
    this.maxDartsPerTurn = 3,
    this.autoCloseAtMaxDarts = false,
    required this.onTurnComplete,
  });

  /// Maximum darts in a turn (standard darts = 3).
  final int maxDartsPerTurn;

  /// If true, the turn auto-closes once [maxDartsPerTurn] darts are buffered,
  /// without waiting for a takeout. Default false: wait for the takeout event,
  /// which is the authoritative boundary and correctly handles busts/checkouts.
  final bool autoCloseAtMaxDarts;

  /// Called with the completed turn's darts when a turn closes.
  final void Function(TurnResult turn) onTurnComplete;

  final List<DetectedThrow> _buffer = <DetectedThrow>[];
  BoardPhase? _phase = BoardPhase.throwing;

  /// Current buffered darts (unmodifiable view, for display/testing).
  List<DetectedThrow> get pending => List.unmodifiable(_buffer);

  /// Update the known board phase. Throws are only accepted while [phase] is
  /// [BoardPhase.throwing].
  void setPhase(BoardPhase? phase) {
    _phase = phase;
  }

  /// Feed a detected dart. Ignored if the board is not in Throw phase or the
  /// buffer is already full.
  void addThrow(DetectedThrow dart) {
    if (_phase != BoardPhase.throwing) return;
    if (_buffer.length >= maxDartsPerTurn) return;
    _buffer.add(dart);
    if (autoCloseAtMaxDarts && _buffer.length >= maxDartsPerTurn) {
      _closeTurn();
    }
  }

  /// Replace an already-buffered dart with a corrected value (before the turn
  /// is submitted). Used for correcting a misclick or a wrong/bounced
  /// detection. Out-of-range indices are ignored. Unlike [addThrow], this is
  /// not subject to the full-buffer or phase guards, since it edits an existing
  /// dart rather than adding a new one.
  void replaceThrow(int index, DetectedThrow dart) {
    if (index < 0 || index >= _buffer.length) return;
    _buffer[index] = dart;
  }

  /// Handle a takeout-finished event. A real takeout closes the turn; a
  /// [falseTakeout] is ignored.
  void onTakeoutFinished({required bool falseTakeout}) {
    if (falseTakeout) return;
    // Move phase back to throwing for the next turn.
    _phase = BoardPhase.throwing;
    // Only emit if darts were actually thrown this turn.
    if (_buffer.isNotEmpty) {
      _closeTurn();
    }
  }

  /// Handle a takeout-started event (board enters Takeout phase; no throws
  /// detected meanwhile).
  void onTakeoutStarted() {
    _phase = BoardPhase.takeout;
  }

  /// Clear buffered darts without emitting a turn. Call on game entry.
  void reset() {
    _buffer.clear();
    _phase = BoardPhase.throwing;
  }

  void _closeTurn() {
    final turn = TurnResult(List<DetectedThrow>.unmodifiable(_buffer));
    _buffer.clear();
    onTurnComplete(turn);
  }
}
