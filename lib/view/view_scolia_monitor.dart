import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_connection.dart';
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
  StreamSubscription<ScoliaConnectionState>? _connSub;

  BoardStatus _status = BoardStatus.offline;
  BoardPhase? _phase;
  String? _highlightSector;
  Timer? _flashTimer;
  ScoliaConnectionState _connState = ScoliaConnectionState.disconnected;
  String? _connError;

  @override
  void initState() {
    super.initState();
    _connSub = widget.source.connectionState.listen((state) {
      setState(() {
        _connState = state;
        if (widget.source is ScoliaConnection) {
          final err = (widget.source as ScoliaConnection).lastError;
          if (err != null) _connError = err;
        }
      });
      final entry = switch (state) {
        ScoliaConnectionState.connecting   => _LogEntry('CONNECTING...', Colors.amberAccent),
        ScoliaConnectionState.connected    => _LogEntry('CONNECTED', Colors.greenAccent),
        ScoliaConnectionState.disconnected => _LogEntry('DISCONNECTED', Colors.white54),
        ScoliaConnectionState.error        => _LogEntry(
            'CONNECTION ERROR: ${(widget.source is ScoliaConnection ? (widget.source as ScoliaConnection).lastError : null) ?? "unknown"}',
            Colors.redAccent),
      };
      setState(() => _log.insert(0, entry));
    });
    _sub = widget.source.messages.listen(_onMessage);
    // Do NOT call connect() here — ScoliaService manages the connection.
    // Sync current known state.
    setState(() {
      _status = widget.source.currentStatus;
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _sub?.cancel();
    _connSub?.cancel();
    // Do NOT call disconnect() — the connection is shared via ScoliaService.
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
      SentMessage(:final raw) =>
        _LogEntry('→ SENT  $raw', Colors.cyanAccent),
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
    final connColor = switch (_connState) {
      ScoliaConnectionState.connected    => Colors.greenAccent,
      ScoliaConnectionState.connecting   => Colors.amberAccent,
      ScoliaConnectionState.error        => Colors.redAccent,
      ScoliaConnectionState.disconnected => Colors.white38,
    };
    return GameLayout(
      title: 'Scolia Monitor',
      mainContent: Column(
        children: [
          // Connection state banner
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.circle, size: 12, color: connColor),
                  const SizedBox(width: 6),
                  Text(
                    'Verbindung: ${_connState.name}'
                    '  · Board: ${_status.name}  · Phase: $phaseText',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ]),
                if (_connError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 18),
                    child: Text(
                      'Fehler: $_connError',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Log + dartboard
          Expanded(
            child: Row(
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
                // ########## Right: dartboard flashing detected hits
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(builder: (context, constraints) {
                            final maxSize =
                                (constraints.maxWidth < constraints.maxHeight
                                        ? constraints.maxWidth
                                        : constraints.maxHeight) -
                                    40;
                            final radius =
                                ((maxSize - 60) / 2).clamp(110.0, 260.0);
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
          ),
        ],
      ),
      statsContent: const SizedBox(),
    );
  }
}
