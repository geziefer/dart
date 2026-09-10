import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/widget/fullcircle.dart';
import 'package:dart/widget/game_layout.dart';

/// Diagnostic monitor for testing the board/API in isolation ("board without
/// app"): it connects to a real [ScoliaEventSource] and, with NO game logic and
/// NO input, shows what the API delivers —
///  - left:  a colour-coded log of raw events
///  - right: the dartboard, flashing the section where each detected dart landed
///
/// Colours: green = status/phase, amber = throws, blue = takeout,
/// red = refused/errors.
class ViewScoliaMonitor extends StatefulWidget {
  const ViewScoliaMonitor({super.key, required this.source});

  final ScoliaEventSource source;

  @override
  State<ViewScoliaMonitor> createState() => _ViewScoliaMonitorState();
}

class _LogEntry {
  final String text;
  final Color color;
  _LogEntry(this.text, this.color);
}

/// A no-op dartboard controller: the monitor is display-only, so taps do
/// nothing.
class _NoInput implements DartboardController {
  @override
  void pressDartboard(String value) {}
}

class _ViewScoliaMonitorState extends State<ViewScoliaMonitor> {
  final List<_LogEntry> _log = [];
  final _NoInput _noInput = _NoInput();
  StreamSubscription<ScoliaMessage>? _sub;

  BoardStatus _status = BoardStatus.offline;
  BoardPhase? _phase;
  String? _highlightSector;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _sub = widget.source.messages.listen(_onMessage);
    widget.source.connect();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _sub?.cancel();
    widget.source.disconnect();
    super.dispose();
  }

  void _flash(String sector) {
    _flashTimer?.cancel();
    setState(() => _highlightSector = sector);
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _highlightSector = null);
    });
  }

  void _onMessage(ScoliaMessage msg) {
    final entry = switch (msg) {
      HelloClientMessage(:final status, :final phase) => _LogEntry(
          'HELLO_CLIENT  status=${status.name} phase=${phase?.name ?? '-'}',
          Colors.greenAccent),
      SbcStatusMessage(:final status, :final phase) => _LogEntry(
          'SBC_STATUS  status=${status.name} phase=${phase?.name ?? '-'}',
          Colors.greenAccent),
      ThrowDetectedMessage(:final detectedThrow, :final sector) => _LogEntry(
          'THROW_DETECTED  sector=$sector value=${detectedThrow.value}',
          Colors.amberAccent),
      TakeoutStartedMessage() =>
        _LogEntry('TAKEOUT_STARTED', Colors.lightBlueAccent),
      TakeoutFinishedMessage(:final falseTakeout) => _LogEntry(
          'TAKEOUT_FINISHED  falseTakeout=$falseTakeout',
          Colors.lightBlueAccent),
      RefusedMessage(:final error) =>
        _LogEntry('REFUSED  error=$error', Colors.redAccent),
      AcknowledgedMessage() => _LogEntry('ACKNOWLEDGED', Colors.white70),
      BoardAvailabilityMessage(:final available) => _LogEntry(
          'AVAILABILITY  available=$available', Colors.greenAccent),
      UnknownMessage(:final type) =>
        _LogEntry('UNKNOWN  type=$type', Colors.white38),
    };

    // Update board state and flash detected hits on the dartboard.
    if (msg is HelloClientMessage) {
      _status = msg.status;
      _phase = msg.phase;
    } else if (msg is SbcStatusMessage) {
      _status = msg.status;
      _phase = msg.phase;
    } else if (msg is ThrowDetectedMessage) {
      _flash(msg.sector ?? 'None');
    }
    setState(() => _log.insert(0, entry));
  }

  @override
  Widget build(BuildContext context) {
    final phaseText = _phase == null
        ? '-'
        : (_phase == BoardPhase.throwing ? 'Throw' : 'Takeout');
    return GameLayout(
      title: 'Scolia Monitor',
      mainContent: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ########## Left: raw event log
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                reverse: true,
                itemCount: _log.length,
                itemBuilder: (context, i) => Text(
                  _log[i].text,
                  style: TextStyle(
                    color: _log[i].color,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(color: Colors.white, thickness: 2),
          // ########## Right: state banner + dartboard flashing detected hits
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'Status: ${_status.name} · Phase: $phaseText',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final maxSize =
                          (constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight) -
                              40;
                      final radius = ((maxSize - 60) / 2).clamp(110.0, 260.0);
                      return FullCircle(
                        controller: _noInput,
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
              ],
            ),
          ),
        ],
      ),
      statsContent: const SizedBox(),
    );
  }
}
