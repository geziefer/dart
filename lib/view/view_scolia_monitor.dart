import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/scolia_service.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/widget/fullcircle.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/interfaces/dartboard_controller.dart';

/// Diagnostic monitor — display-only. Reads the persistent message log from
/// [ScoliaService] and subscribes to live messages. Re-subscribes automatically
/// when the service reconnects (new source). No game logic, no input.
class ViewScoliaMonitor extends StatefulWidget {
  const ViewScoliaMonitor({super.key});

  @override
  State<ViewScoliaMonitor> createState() => _ViewScoliaMonitorState();
}

class _NoInput implements DartboardController {
  @override
  void pressDartboard(String value) {}
}

class _ViewScoliaMonitorState extends State<ViewScoliaMonitor> {
  final _noInput = _NoInput();
  StreamSubscription<ScoliaMessage>? _sub;
  ScoliaEventSource? _lastSource;
  String? _highlightSector;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-subscribe if service's source changed (reconnect created new source).
    _subscribe();
  }

  void _subscribe() {
    if (!mounted) return;
    final svc = context.read<ScoliaService?>();
    final src = svc?.source;
    if (src == null || src == _lastSource) return;
    _sub?.cancel();
    _sub = src.messages.listen(_onMessage);
    _lastSource = src;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _onMessage(ScoliaMessage msg) {
    if (msg is ThrowDetectedMessage) {
      _flash(msg.sector ?? 'None');
    }
    // Log is maintained by ScoliaService — no local list needed.
  }

  void _flash(String sector) {
    _flashTimer?.cancel();
    setState(() => _highlightSector = sector);
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _highlightSector = null);
    });
  }

  Color _colorFor(ScoliaMessage msg) {
    if (msg is ThrowDetectedMessage) return Colors.amberAccent;
    if (msg is TakeoutStartedMessage || msg is TakeoutFinishedMessage) {
      return Colors.lightBlueAccent;
    }
    if (msg is HelloClientMessage || msg is SbcStatusMessage) {
      return Colors.greenAccent;
    }
    if (msg is RefusedMessage) return Colors.redAccent;
    if (msg is SentMessage) return Colors.cyanAccent;
    if (msg is UnknownMessage) {
      final t = msg.type;
      if (t.startsWith('__CONNECTED')) return Colors.greenAccent;
      if (t.startsWith('__DISCONNECTED') || t.startsWith('__FAILED')) {
        return Colors.redAccent;
      }
      if (t.startsWith('__RETRY')) return Colors.orange;
      return Colors.white38;
    }
    return Colors.white70;
  }

  String _labelFor(ScoliaMessage msg) {
    return switch (msg) {
      HelloClientMessage(:final status, :final phase) =>
        'HELLO_CLIENT  status=${status.name} phase=${phase?.name ?? '-'}',
      SbcStatusMessage(:final status, :final phase) =>
        'SBC_STATUS  status=${status.name} phase=${phase?.name ?? '-'}',
      ThrowDetectedMessage(:final detectedThrow, :final sector) =>
        'THROW_DETECTED  sector=$sector value=${detectedThrow.value}',
      TakeoutStartedMessage() => 'TAKEOUT_STARTED',
      TakeoutFinishedMessage(:final falseTakeout) =>
        'TAKEOUT_FINISHED  falseTakeout=$falseTakeout',
      RefusedMessage(:final error) => 'REFUSED  error=$error',
      AcknowledgedMessage() => 'ACKNOWLEDGED',
      BoardAvailabilityMessage(:final available) =>
        'AVAILABILITY  available=$available',
      SentMessage(:final raw) => '→ SENT  $raw',
      UnknownMessage(:final type) => switch (type) {
          '__DISCONNECTED__' => '── DISCONNECTED ──',
          '__FAILED__'       => '── RETRIES EXHAUSTED ──',
          String s when s.startsWith('__RETRY_') =>
            '── Retry ${s.replaceAll('__RETRY_', '').replaceAll('_', '')}/${ScoliaService.maxRetries} ──',
          _ => 'UNKNOWN  type=$type',
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ScoliaService?>();
    final log = svc?.messageLog ?? [];

    final connColor = switch (svc?.serviceState) {
      ScoliaServiceState.connected    => Colors.greenAccent,
      ScoliaServiceState.connecting   => Colors.amberAccent,
      ScoliaServiceState.reconnecting => Colors.orange,
      ScoliaServiceState.failed       => Colors.redAccent,
      _ => Colors.white38,
    };
    final connText = switch (svc?.serviceState) {
      ScoliaServiceState.connected    => 'Verbunden · Board: ${svc?.boardStatus.name}',
      ScoliaServiceState.connecting   => 'Verbinde...',
      ScoliaServiceState.reconnecting => 'Reconnecting (${svc?.retryCount}/${ScoliaService.maxRetries})...',
      ScoliaServiceState.failed       => 'Getrennt  ↻ Tippen',
      _ => 'Inaktiv',
    };

    return GameLayout(
      title: 'Scolia Monitor',
      mainContent: Column(
        children: [
          // Connection banner
          GestureDetector(
            onTap: svc?.canManualRetry == true ? () => svc?.reconnect() : null,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(children: [
                Icon(Icons.circle, size: 12, color: connColor),
                const SizedBox(width: 6),
                Text(connText,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (svc?.canManualRetry == true) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.refresh, size: 14, color: Colors.white70),
                ],
              ]),
            ),
          ),
          // Log + dartboard
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: persistent event log
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    child: log.isEmpty
                        ? const Center(
                            child: Text('Keine Events',
                                style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            reverse: true,
                            itemCount: log.length,
                            itemBuilder: (context, i) => Text(
                              _labelFor(log[i]),
                              style: TextStyle(
                                color: _colorFor(log[i]),
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ),
                const VerticalDivider(color: Colors.white, thickness: 2),
                // Right: dartboard flashing detected hits
                Expanded(
                  flex: 5,
                  child: Column(children: [
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(builder: (context, constraints) {
                          final maxSize = (constraints.maxWidth <
                                      constraints.maxHeight
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
                  ]),
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
