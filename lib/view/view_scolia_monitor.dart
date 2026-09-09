import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dart/scolia/mock_scolia_source.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/widget/game_layout.dart';

/// Diagnostic monitor: connects to a [ScoliaEventSource] and shows the raw
/// event stream in a colour-coded log. Used to test the board/API in isolation
/// ("board without app") — no game logic involved.
///
/// Colours:
/// - green  : status / phase / connection
/// - amber  : throws
/// - blue   : takeout
/// - red    : refused / errors
class ViewScoliaMonitor extends StatefulWidget {
  const ViewScoliaMonitor({super.key, required this.source, this.simulator = false});

  final ScoliaEventSource source;
  final bool simulator;

  @override
  State<ViewScoliaMonitor> createState() => _ViewScoliaMonitorState();
}

class _LogEntry {
  final String text;
  final Color color;
  _LogEntry(this.text, this.color);
}

class _ViewScoliaMonitorState extends State<ViewScoliaMonitor> {
  final List<_LogEntry> _log = [];
  StreamSubscription<ScoliaMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.source.messages.listen(_onMessage);
    widget.source.connect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.source.disconnect();
    super.dispose();
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
    setState(() => _log.insert(0, entry));
  }

  @override
  Widget build(BuildContext context) {
    return GameLayout(
      title: 'Scolia Monitor',
      mainContent: Column(
        children: [
          if (widget.simulator) _simulatorControls(),
          Expanded(
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
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      statsContent: const SizedBox(),
    );
  }

  Widget _simulatorControls() {
    final mock = widget.source as MockScoliaSource;
    return Wrap(
      spacing: 8,
      children: [
        for (final s in ['T20', 'S20', 'D16', '25', 'Bull', 'None'])
          ElevatedButton(
            onPressed: () => mock.throwSector(s),
            child: Text(s),
          ),
        ElevatedButton(
          onPressed: () => mock.takeoutStarted(),
          child: const Text('Takeout start'),
        ),
        ElevatedButton(
          onPressed: () => mock.takeoutFinished(),
          child: const Text('Takeout end'),
        ),
      ],
    );
  }
}
