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
  });

  /// The active game controller (must support Scolia input).
  final ScoliaController controller;

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
  }

  @override
  void dispose() {
    widget.onTimerExpiredNotifier?.removeListener(_onTimerExpired);
    _flashTimer?.cancel();
    _sub?.cancel();
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
        // While correcting on screen, ignore incoming board detections.
        if (_editIndex != null) break;
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
      widget.onCorrectionModeChanged?.call(false);
      return;
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

  void _onTurnComplete(TurnResult turn) {
    widget.controller.submitScoliaTurn(turn);
    setState(() {});
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
              onPressed: widget.onUndoRound,
              icon: const Icon(Icons.undo, color: Colors.white),
            ),
            IconButton(
              tooltip: editing ? 'Auf 0 korrigieren' : 'Fehlwurf (0)',
              iconSize: 36,
              onPressed: (!editing && _turnFull) ? null : _missThrow,
              icon: const Icon(Icons.block, color: Colors.white),
            ),
            if (widget.simulator)
              IconButton(
                tooltip: 'Darts rausnehmen',
                iconSize: 36,
                onPressed: _endTurn,
                icon: const Icon(Icons.pan_tool, color: Colors.white),
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
          ),
        const Divider(color: Colors.white24),
        // The (up to 3) thrown darts, stacked, in a large font. Each is a
        // button: tap to select it for correction (then tap the board / a
        // ring / the 0 icon to set the corrected value).
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _collector.pending.length; i++)
                _pendingDart(i, _collector.pending[i]),
            ],
          ),
        ),
      ],
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
