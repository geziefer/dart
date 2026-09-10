import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:dart/scolia/scolia_controller.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/turn_collector.dart';
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
  });

  /// The active game controller (must support Scolia input).
  final ScoliaController controller;

  /// Optional real event source. When null (or [simulator] true), the board is
  /// tap-driven.
  final ScoliaEventSource? source;

  /// True = simulator (taps generate throws). False = real board drives it.
  final bool simulator;

  @override
  State<ScoliaDartboard> createState() => _ScoliaDartboardState();
}

class _ScoliaDartboardState extends State<ScoliaDartboard>
    implements DartboardController {
  late final TurnCollector _collector;
  StreamSubscription<ScoliaMessage>? _sub;

  BoardStatus _status = BoardStatus.ready;
  BoardPhase? _phase = BoardPhase.throwing;

  @override
  void initState() {
    super.initState();
    _collector = TurnCollector(onTurnComplete: _onTurnComplete);
    if (!widget.simulator && widget.source != null) {
      _sub = widget.source!.messages.listen(_onMessage);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
      case ThrowDetectedMessage(:final detectedThrow):
        _registerThrow(detectedThrow);
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
    if (!widget.simulator) return; // real board is authoritative
    final sector = _normalizeSector(value);
    _registerThrow(SectorParser.parse(sector));
  }

  /// FullCircle emits `DB` (inner bull) and `SB` (outer bull); Scolia's sector
  /// grammar uses `Bull` and `25`. Normalise so the real parser is exercised.
  String _normalizeSector(String v) {
    if (v == 'DB') return 'Bull';
    if (v == 'SB') return '25';
    return v;
  }

  /// True once the current turn already has the maximum darts; further throws
  /// are ignored until a takeout closes the turn (mirrors the real board, which
  /// detects no throws once 3 darts are in and a takeout is pending).
  bool get _turnFull => _collector.pending.length >= 3;

  void _registerThrow(DetectedThrow t) {
    if (widget.simulator && _turnFull) return; // no more than 3 darts
    _collector.addThrow(t);
    setState(() {});
  }

  /// Simulate a missed dart (Scolia would report sector "None" / bounceout).
  void _missThrow() {
    if (_turnFull) return;
    _registerThrow(DetectedThrow.miss());
  }

  void _endTurn() {
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
                      arcSections: [
                        ArcSection(startPercent: 0.2),
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
    return Column(
      children: [
        // Simulator controls: miss (0) and takeout (end turn), top of column.
        if (widget.simulator)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Fehlwurf (0)',
                iconSize: 40,
                onPressed: _turnFull ? null : _missThrow,
                icon: const Icon(Icons.block, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Darts rausnehmen',
                iconSize: 40,
                onPressed: _endTurn,
                icon: const Icon(Icons.pan_tool, color: Colors.white),
              ),
            ],
          ),
        const Divider(color: Colors.white24),
        // The (up to 3) thrown darts, stacked, in a large font.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final t in _collector.pending)
                Text(
                  t.ring == DartRing.miss ? '–' : '${t.value}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 215, 198, 132),
                    fontWeight: FontWeight.bold,
                    fontSize: 56,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBanner() {
    final phaseText = _phase == null
        ? '-'
        : (_phase == BoardPhase.throwing ? 'Throw' : 'Takeout');
    final statusColor =
        _status == BoardStatus.ready ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 20, color: statusColor),
          const SizedBox(width: 8),
          Text(
            '${widget.simulator ? 'Simulator' : 'Scolia'} · Status: '
            '${_status.name} · Phase: $phaseText',
            style: const TextStyle(color: Colors.white, fontSize: 26),
          ),
        ],
      ),
    );
  }
}
