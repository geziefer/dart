import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:dart/scolia/scolia_controller.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/scolia_service.dart';
import 'package:dart/scolia/turn_collector.dart';
import 'package:dart/services/dart_target.dart';
import 'package:dart/services/throw_log_model.dart';
import 'package:dart/services/throw_log_service.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/widget/fullcircle.dart';

/// The Scolia input surface: a dartboard that replaces the numpad when Scolia
/// mode is active.
///
/// - **Simulator mode:** the user taps the board; each tap is a simulated throw.
/// - **Real mode:** an attached [ScoliaEventSource] delivers THROW_DETECTED and
///   the hit is displayed. (The same taps path is disabled; the board mirrors
///   the physical board.)
///
/// Either way the throw flows through the identical pipeline
/// (SectorParser -> TurnCollector -> controller.submitScoliaTurn), so this
/// widget is faithful to the real integration and also serves as a live monitor
/// (status/phase banner + recent throws).
class ScoliaDartboard extends StatefulWidget {
  const ScoliaDartboard({
    super.key,
    required this.controller,
    this.source,
    this.simulator = true,
    this.onUndoRound,
    this.onCorrectionModeChanged,
    this.onFirstDart,
    this.onTimerExpiredNotifier,
    this.gameId,
  });

  /// The active game controller (must support Scolia input).
  final ScoliaController controller;

  /// Storage container id of the game being played. When provided, the darts
  /// thrown this session are logged to the [ThrowLogService] on dispose (one
  /// [ThrowSession] per game, flushed once at session end — never per dart).
  final String? gameId;

  /// Optional real event source. When null (or [simulator] true), the board is
  /// tap-driven.
  final ScoliaEventSource? source;

  /// True = simulator (taps generate throws). False = real board drives it.
  final bool simulator;

  /// Called when the user requests to undo the last completed round. The view
  /// wires this to the game controller's existing round-undo (numpad `-2`),
  /// so full round-undo works identically in Scolia mode.
  final VoidCallback? onUndoRound;

  /// Called when correction mode is entered (true) or exited (false).
  /// Allows time-sensitive games (e.g. Speed Bull) to pause/resume their timer.
  final void Function(bool correcting)? onCorrectionModeChanged;

  /// Called when the very first dart of a turn is registered. Fires before the
  /// turn completes — allows time-sensitive games to start their timer on the
  /// first throw rather than waiting for the takeout.
  final VoidCallback? onFirstDart;

  /// When provided, the dartboard listens to this notifier and immediately
  /// submits the current partial turn when it fires. Used by Speed Bull to
  /// submit buffered darts when the timer reaches 0.
  final ValueNotifier<bool>? onTimerExpiredNotifier;

  @override
  State<ScoliaDartboard> createState() => _ScoliaDartboardState();
}

class _ScoliaDartboardState extends State<ScoliaDartboard>
    implements DartboardController {
  late final TurnCollector _collector;
  StreamSubscription<ScoliaMessage>? _sub;

  BoardStatus _status = BoardStatus.ready;
  BoardPhase? _phase = BoardPhase.throwing;

  /// Index of the pending dart currently selected for correction, or null.
  int? _editIndex;

  /// The darts of the most recently submitted turn, kept visible as a
  /// "committed" round so the user can correct a misread dart after takeout.
  /// Null before the first turn is submitted or after a new turn starts.
  List<DetectedThrow>? _lastTurn;

  /// True while [_lastTurn] is being shown as a committed (already-submitted)
  /// round and no new darts have been thrown yet. The next new throw clears it
  /// and starts a fresh turn.
  bool _showingCommitted = false;

  /// True while a post-submit correction is in progress: the last round has
  /// been undone and its darts reloaded into the collector for editing. On the
  /// next takeout the edited turn is re-submitted through the normal path.
  bool _correctingLastRound = false;

  /// Accumulates every submitted dart of the current session for the throw
  /// log. Flushed once as a [ThrowSession] on dispose (session end). Each
  /// submitted turn appends its darts; a post-submit correction removes the
  /// last turn's darts before the corrected turn re-adds them.
  final List<LoggedDart> _sessionDarts = <LoggedDart>[];

  /// Number of darts the last submitted turn contributed to [_sessionDarts],
  /// so a post-submit correction can remove exactly those before re-submitting.
  int _lastTurnDartCount = 0;

  /// Captured once (from context) so dispose can flush without context access.
  ThrowLogService? _throwLog;

  /// Sector currently flashed on the board (brief white highlight), or null.
  String? _highlightSector;
  Timer? _flashTimer;

  /// Briefly flash [sector] on the board (like the numpad key highlight).
  void _flash(String sector) {
    _flashTimer?.cancel();
    setState(() => _highlightSector = sector);
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _highlightSector = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _collector = TurnCollector(onTurnComplete: _onTurnComplete);
    // Listen to timer-expired notifier (Speed Bull: submit partial turn at 0).
    widget.onTimerExpiredNotifier?.addListener(_onTimerExpired);
    // Trigger connect after first frame so context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final svc = context.read<ScoliaService?>();
      final isSimulator = widget.source != null
          ? widget.simulator
          : (svc?.isSimulator ?? true);
      if (!isSimulator) svc?.connect();
      _subscribeToSource();
    });
  }

  ScoliaEventSource? _lastSource;

  void _subscribeToSource() {
    if (!mounted) return;
    final svc = context.read<ScoliaService?>();
    final effectiveSource = widget.source ?? svc?.source;
    final effectiveSimulator = widget.source != null
        ? widget.simulator
        : (svc?.isSimulator ?? true);
    if (!effectiveSimulator && effectiveSource != null &&
        effectiveSource != _lastSource) {
      _sub?.cancel();
      _sub = effectiveSource.messages.listen(_onMessage);
      _lastSource = effectiveSource;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-subscribe if the service's source changed (e.g. after reconnect).
    _subscribeToSource();
    // Capture the throw-log service so dispose() can flush the session without
    // touching context (which is unavailable during dispose).
    _throwLog ??= context.read<ThrowLogService?>();
  }

  @override
  void dispose() {
    widget.onTimerExpiredNotifier?.removeListener(_onTimerExpired);
    _flashTimer?.cancel();
    _sub?.cancel();
    _flushSession();
    super.dispose();
  }

  void _onTimerExpired() {
    // Timer reached 0 — submit whatever darts are buffered immediately.
    if (_collector.pending.isNotEmpty) {
      _endTurn();
    }
  }

  // --- Real-mode message handling ---
  void _onMessage(ScoliaMessage msg) {
    switch (msg) {
      case HelloClientMessage(:final status, :final phase):
      case SbcStatusMessage(:final status, :final phase):
        setState(() {
          _status = status;
          _phase = phase;
        });
        _collector.setPhase(phase);
      case ThrowDetectedMessage(:final detectedThrow, :final sector):
        // While correcting on screen (per-dart edit or an in-progress
        // post-submit correction of the last round), ignore incoming board
        // detections so a stray detection can't disturb the correction.
        if (_editIndex != null || _correctingLastRound) break;
        _flash(sector ?? 'None'); // mirror the board: flash the detected sector
        _applyHit(detectedThrow);
      case TakeoutStartedMessage():
        _collector.onTakeoutStarted();
        setState(() => _phase = BoardPhase.takeout);
      case TakeoutFinishedMessage(:final falseTakeout):
        _collector.onTakeoutFinished(falseTakeout: falseTakeout);
        setState(() => _phase = BoardPhase.throwing);
      default:
        break;
    }
  }

  // --- Simulator: dartboard taps ---
  @override
  void pressDartboard(String value) {
    // In real Scolia mode the board is authoritative for new throws;
    // only accept taps when in correction mode (a dart is selected).
    final effectiveSimulator = widget.source != null
        ? widget.simulator
        : (context.read<ScoliaService?>()?.isSimulator ?? true);
    if (!effectiveSimulator && _editIndex == null) return;
    _flash(value);
    final sector = _normalizeSector(value);
    _applyHit(SectorParser.parse(sector));
  }

  /// FullCircle emits `DB` (inner bull), `SB` (outer bull), and `s` (inner
  /// single). Normalise only the bull notations so the pipeline parser gets
  /// valid input. Keep `s` as-is so SectorParser can set isOuterSingle=false.
  String _normalizeSector(String v) {
    if (v == 'DB') return 'Bull';
    if (v == 'SB') return '25';
    return v;
  }

  /// True once the current turn already has the maximum darts; further throws
  /// are ignored until a takeout closes the turn (mirrors the real board, which
  /// detects no throws once 3 darts are in and a takeout is pending).
  bool get _turnFull => _collector.pending.length >= 3;

  /// Apply a hit: if a dart is selected for correction, replace it; otherwise
  /// add it as a new throw (subject to the 3-dart cap).
  void _applyHit(DetectedThrow t) {
    if (_editIndex != null) {
      _collector.replaceThrow(_editIndex!, t);
      setState(() => _editIndex = null);
      // During post-submit correction we stay in the correcting turn until the
      // takeout re-submits it; only clear the on-screen edit affordance.
      if (!_correctingLastRound) {
        widget.onCorrectionModeChanged?.call(false);
      }
      return;
    }
    // A genuinely new throw: if a committed round is still shown, clear it and
    // start a fresh turn (the committed darts stay in _lastTurn history only).
    if (_showingCommitted) {
      setState(() => _showingCommitted = false);
      _collector.reset();
    }
    if (_turnFull) return; // no more than 3 darts
    // Fire onFirstDart when the buffer transitions from empty to 1 dart.
    if (_collector.pending.isEmpty) {
      widget.onFirstDart?.call();
    }
    _collector.addThrow(t);
    setState(() {});
  }

  /// Enter/exit correction mode for pending dart [index].
  void _toggleEdit(int index) {
    final newIndex = _editIndex == index ? null : index;
    setState(() => _editIndex = newIndex);
    widget.onCorrectionModeChanged?.call(newIndex != null);
  }

  /// Miss / 0 control: either corrects the selected dart to 0 (e.g. a bounced
  /// dart that was wrongly scored) or adds a new 0-value dart.
  void _missThrow() {
    if (_editIndex == null && _turnFull) return;
    _flash('None');
    _applyHit(DetectedThrow.miss());
  }

  void _endTurn() {
    if (_editIndex != null) {
      setState(() => _editIndex = null);
      widget.onCorrectionModeChanged?.call(false);
    }
    // Simulate a real takeout to close the turn.
    _collector.onTakeoutFinished(falseTakeout: false);
  }

  /// Whole-round undo (undo icon): roll back the game by one round and drop the
  /// last submitted turn's darts from the session log, so the log mirrors the
  /// game state.
  void _undoRound() {
    widget.onUndoRound?.call();
    if (_lastTurnDartCount > 0 &&
        _sessionDarts.length >= _lastTurnDartCount) {
      _sessionDarts.removeRange(
          _sessionDarts.length - _lastTurnDartCount, _sessionDarts.length);
    }
    _lastTurnDartCount = 0;
    setState(() {
      _showingCommitted = false;
      _lastTurn = null;
    });
  }

  /// Flush the accumulated session darts as one [ThrowSession] to the throw
  /// log. Called once on dispose (session end). No-op without a game id, a
  /// throw-log service, or any darts.
  void _flushSession() {
    final gameId = widget.gameId;
    final log = _throwLog;
    if (gameId == null || log == null || _sessionDarts.isEmpty) return;
    log.logSession(ThrowSession(
      gameId: gameId,
      date: DateTime.now(),
      fromScolia: true,
      darts: List<LoggedDart>.of(_sessionDarts),
    ));
  }

  void _onTurnComplete(TurnResult turn) {
    widget.controller.submitScoliaTurn(turn);
    // Record the submitted darts for the session throw log (flushed on
    // dispose), pairing each with the controller's intended target (if any).
    // Track this turn's count so a post-submit correction can remove exactly
    // these darts before the corrected turn re-adds them.
    final controller = widget.controller;
    final targets = controller is AimTargetReporting
        ? (controller as AimTargetReporting).targetsForLastTurn()
        : const <DartTarget?>[];
    for (int i = 0; i < turn.darts.length; i++) {
      final target = i < targets.length ? targets[i] : null;
      _sessionDarts.add(LoggedDart.fromDetected(turn.darts[i], target: target));
    }
    _lastTurnDartCount = turn.darts.length;
    setState(() {
      // Keep the just-submitted darts on screen as a "committed" round so the
      // user can still correct a misread dart (post-submit correction). The
      // next new throw clears this and starts a fresh turn.
      _lastTurn = List<DetectedThrow>.of(turn.darts);
      _showingCommitted = true;
      _correctingLastRound = false;
    });
  }

  /// Whether post-submit correction of the last round is currently offered:
  /// a committed round is on screen, we are not already editing/correcting,
  /// the game is still in play, and the view wired a round-undo callback.
  bool get _canCorrectLastRound =>
      _showingCommitted &&
      !_correctingLastRound &&
      _editIndex == null &&
      (_lastTurn?.isNotEmpty ?? false) &&
      widget.onUndoRound != null;

  /// Start correcting the committed last round: undo the whole round in the
  /// game (the mechanism every Scolia view already wires), then reload that
  /// round's darts into the collector as the current turn and select dart
  /// [index] for correction. On the next takeout the edited turn is
  /// re-submitted through [submitScoliaTurn] — equivalent by construction to
  /// having thrown the corrected dart in the first place.
  void _startPostSubmitCorrection(int index) {
    final last = _lastTurn;
    if (last == null || last.isEmpty) return;
    if (widget.onUndoRound == null) return;

    // Roll the game state back by one round.
    widget.onUndoRound!.call();

    // Remove the darts this turn contributed to the session log; the corrected
    // turn will re-add its darts when it is re-submitted, so the log reflects
    // the corrected round (not the original misread).
    if (_lastTurnDartCount > 0 &&
        _sessionDarts.length >= _lastTurnDartCount) {
      _sessionDarts.removeRange(
          _sessionDarts.length - _lastTurnDartCount, _sessionDarts.length);
      _lastTurnDartCount = 0;
    }

    // Reload the round's darts into the collector buffer for editing.
    _collector.reset();
    for (final d in last) {
      _collector.addThrow(d);
    }

    setState(() {
      _showingCommitted = false;
      _correctingLastRound = true;
      _editIndex = index;
    });
    widget.onCorrectionModeChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _statusBanner(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ########## Dartboard
              Expanded(
                flex: 7,
                child: Center(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final maxSize =
                        (constraints.maxWidth < constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight) -
                            40;
                    final radius = ((maxSize - 60) / 2).clamp(110.0, 260.0);
                    return FullCircle(
                      controller: this,
                      radius: radius,
                      highlightSector: _highlightSector,
                      arcSections: [
                        ArcSection(startPercent: 0.245),
                        ArcSection(startPercent: 0.35),
                        ArcSection(startPercent: 0.55),
                        ArcSection(startPercent: 0.8),
                      ],
                    );
                  }),
                ),
              ),
              // ########## Right column: icons on top, thrown numbers below
              Expanded(
                flex: 3,
                child: _rightColumn(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn() {
    final editing = _editIndex != null;
    return Column(
      children: [
        // Controls: undo round, miss/0, takeout. Shown in both modes so
        // corrections and round-undo are always available.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Runde zurück',
              iconSize: 36,
              onPressed: widget.onUndoRound == null ? null : _undoRound,
              icon: const Icon(Icons.undo, color: Colors.white),
            ),
            IconButton(
              tooltip: editing ? 'Auf 0 korrigieren' : 'Fehlwurf (0)',
              iconSize: 36,
              onPressed: (!editing && _turnFull) ? null : _missThrow,
              icon: const Icon(Icons.block, color: Colors.white),
            ),
            if (widget.simulator || _correctingLastRound)
              IconButton(
                tooltip: _correctingLastRound
                    ? 'Korrektur übernehmen'
                    : 'Darts rausnehmen',
                iconSize: 36,
                onPressed: _endTurn,
                icon: Icon(
                    _correctingLastRound ? Icons.check : Icons.pan_tool,
                    color: Colors.white),
              ),
          ],
        ),
        if (editing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Feld antippen zum Korrigieren',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          )
        else if (_canCorrectLastRound)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Dart antippen zum Korrigieren',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        const Divider(color: Colors.white24),
        // The (up to 3) thrown darts, stacked, in a large font.
        //
        // - Live/correcting turn: show the collector's pending darts; each is a
        //   button to select it for correction, then tap the board/0 icon.
        // - Committed round (just submitted): show the retained last turn as a
        //   dimmed, still-tappable list; tapping a dart undoes the round and
        //   reopens it for correction (post-submit correction).
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showingCommitted && _collector.pending.isEmpty)
                for (int i = 0; i < (_lastTurn?.length ?? 0); i++)
                  _committedDart(i, _lastTurn![i])
              else
                for (int i = 0; i < _collector.pending.length; i++)
                  _pendingDart(i, _collector.pending[i]),
            ],
          ),
        ),
      ],
    );
  }

  /// A dart of the committed (already-submitted) last round. Tapping it starts
  /// post-submit correction for that dart. Rendered dimmed to signal it is
  /// already scored.
  Widget _committedDart(int index, DetectedThrow t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _canCorrectLastRound
              ? () => _startPostSubmitCorrection(index)
              : null,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(
                  color: Color.fromARGB(60, 215, 198, 132), width: 1.5),
            ),
          ),
          child: Text(
            t.sectorLabel,
            style: const TextStyle(
              color: Color.fromARGB(130, 215, 198, 132),
              fontWeight: FontWeight.bold,
              fontSize: 56,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pendingDart(int index, DetectedThrow t) {
    final selected = _editIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: double.infinity, // fill the right column width uniformly
        child: TextButton(
          onPressed: () => _toggleEdit(index),
          style: TextButton.styleFrom(
            backgroundColor:
                selected ? const Color.fromARGB(80, 215, 198, 132) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: selected
                  ? const BorderSide(
                      color: Color.fromARGB(255, 215, 198, 132), width: 3)
                  : const BorderSide(
                      color: Color.fromARGB(120, 215, 198, 132), width: 1.5),
            ),
          ),
        child: Text(
          t.sectorLabel,
          style: const TextStyle(
            color: Color.fromARGB(255, 215, 198, 132),
            fontWeight: FontWeight.bold,
            fontSize: 56,
          ),
        ),
      ),
      ),
    );
  }

  Widget _statusBanner() {
    final phaseText = _phase == null
        ? '-'
        : (_phase == BoardPhase.throwing ? 'Throw' : 'Takeout');
    final svc = context.watch<ScoliaService?>();
    final isSimulator = svc?.isSimulator ?? widget.simulator;

    Color statusColor;
    String statusText;
    if (isSimulator) {
      statusColor = Colors.green;
      statusText = 'Simulator · Status: ready · Phase: $phaseText';
    } else {
      switch (svc?.serviceState) {
        case ScoliaServiceState.connected:
          statusColor = _status == BoardStatus.ready ? Colors.green : Colors.orange;
          statusText = 'Scolia · Status: ${_status.name} · Phase: $phaseText';
        case ScoliaServiceState.connecting:
          statusColor = Colors.amberAccent;
          statusText = 'Scolia · Verbinde...';
        case ScoliaServiceState.reconnecting:
          statusColor = Colors.orange;
          statusText = 'Scolia · Reconnecting (${svc?.retryCount}/${ScoliaService.maxRetries})...';
        case ScoliaServiceState.failed:
          statusColor = Colors.red;
          statusText = 'Scolia · Getrennt ↻ Tippen zum Verbinden';
        default:
          statusColor = Colors.grey;
          statusText = 'Scolia · Inaktiv';
      }
    }
    final showRefresh = !isSimulator && svc?.canManualRetry == true;

    return GestureDetector(
      onTap: showRefresh ? () => svc?.reconnect() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        color: Colors.black26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 20, color: statusColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 26)),
            ),
            if (showRefresh) ...[
              const SizedBox(width: 8),
              const Icon(Icons.refresh, size: 20, color: Colors.white70),
            ],
          ],
        ),
      ),
    );
  }
}
