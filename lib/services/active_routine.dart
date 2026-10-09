import 'package:flutter/foundation.dart';

import 'package:dart/services/routine_generator.dart';

/// Runtime state of a routine currently being played (C1).
///
/// In-memory only — a routine in progress is a transient session, not persisted
/// across app restarts. Tracks which game in the routine comes next; the menu
/// consults this to offer a "next up" prompt after each game.
class ActiveRoutine extends ChangeNotifier {
  Routine? _routine;
  int _index = 0; // index of the NEXT game to launch

  /// Whether a routine is currently active with games still to play.
  bool get isActive => _routine != null && _index < _routine!.gameIds.length;

  /// The game id to launch next, or null when none remains.
  String? get nextGameId =>
      isActive ? _routine!.gameIds[_index] : null;

  /// 1-based position of the next game (for display, e.g. "2/3").
  int get position => _index + 1;

  /// Total games in the active routine (0 when none).
  int get total => _routine?.gameIds.length ?? 0;

  /// Begin playing [routine] from the first game.
  void start(Routine routine) {
    _routine = routine;
    _index = 0;
    notifyListeners();
  }

  /// Advance past the game just launched/finished. Auto-ends when the last
  /// game is passed.
  void advance() {
    if (_routine == null) return;
    _index++;
    if (_index >= _routine!.gameIds.length) {
      _routine = null;
      _index = 0;
    }
    notifyListeners();
  }

  /// Cancel the active routine.
  void cancel() {
    _routine = null;
    _index = 0;
    notifyListeners();
  }
}
