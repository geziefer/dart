/// App-level Scolia service: owns the single global WebSocket connection,
/// manages connect/disconnect/auto-retry/keep-alive, and exposes all
/// connection state to the widget tree via ChangeNotifier.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dart/scolia/mock_scolia_source.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_connection.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/scolia_settings.dart';

enum ScoliaServiceState {
  idle,         // not yet connected
  connecting,   // opening the WebSocket
  connected,    // WebSocket open, board may be online or offline
  reconnecting, // lost connection, retrying automatically
  failed,       // auto-retries exhausted, waiting for manual reconnect
}

class ScoliaService extends ChangeNotifier {
  ScoliaService({required this.settings});

  final ScoliaSettings settings;

  // ---- Public state (readable by widgets via context.watch) ----
  ScoliaServiceState serviceState = ScoliaServiceState.idle;
  BoardStatus boardStatus = BoardStatus.offline;
  BoardPhase? boardPhase;
  int retryCount = 0; // current auto-retry attempt (0-3)
  static const maxRetries = 3;
  static const _retryDelays = [3, 6, 12]; // seconds
  static const maxLogEntries = 100;

  bool get canManualRetry => serviceState == ScoliaServiceState.failed;
  bool get isSimulator => settings.simulatorEnabled || !settings.isConfigured;

  // Persistent message log (survives view transitions, capped at maxLogEntries).
  final List<ScoliaMessage> messageLog = [];

  // ---- Private ----
  ScoliaEventSource? _source;
  StreamSubscription<ScoliaMessage>? _messageSub;
  StreamSubscription<ScoliaConnectionState>? _connSub;
  Timer? _retryTimer;
  Timer? _keepAliveTimer;

  /// The active event source — widgets subscribe to this for throw events.
  ScoliaEventSource? get source => _source;

  /// Start the connection. No-op if already connected/connecting.
  Future<void> connect() async {
    if (serviceState == ScoliaServiceState.connecting ||
        serviceState == ScoliaServiceState.connected) {
      return;
    }
    _cancelTimers();
    retryCount = 0;
    await _doConnect();
  }

  /// Manual reconnect after auto-retries exhausted.
  Future<void> reconnect() async {
    if (!canManualRetry && serviceState != ScoliaServiceState.failed) {
      return;
    }
    retryCount = 0;
    serviceState = ScoliaServiceState.connecting;
    notifyListeners();
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _cleanupSource();
    serviceState = ScoliaServiceState.connecting;
    notifyListeners();

    _source = isSimulator
        ? MockScoliaSource()
        : ScoliaConnection(
            serialNumber: settings.serialNumber,
            accessToken: settings.accessToken,
          );

    _connSub = _source!.connectionState.listen(_onConnState);
    _messageSub = _source!.messages.listen(_onMessage);

    await _source!.connect();
  }

  void _onConnState(ScoliaConnectionState state) {
    if (state == ScoliaConnectionState.connected) {
      serviceState = ScoliaServiceState.connected;
      retryCount = 0;
      _addLogEntry(const UnknownMessage(null, '__CONNECTED__'));
      _startKeepAlive();
      notifyListeners();
    } else if (state == ScoliaConnectionState.disconnected ||
        state == ScoliaConnectionState.error) {
      _stopKeepAlive();
      boardStatus = BoardStatus.offline;
      boardPhase = null;
      _addLogEntry(const UnknownMessage(null, '__DISCONNECTED__'));
      _scheduleRetry();
    }
  }

  void _onMessage(ScoliaMessage msg) {
    _addLogEntry(msg);
    if (msg is HelloClientMessage) {
      boardStatus = msg.status;
      boardPhase = msg.phase;
      notifyListeners();
    } else if (msg is SbcStatusMessage) {
      boardStatus = msg.status;
      boardPhase = msg.phase;
      notifyListeners();
    }
  }

  void _addLogEntry(ScoliaMessage msg) {
    messageLog.insert(0, msg);
    if (messageLog.length > maxLogEntries) {
      messageLog.removeLast();
    }
    notifyListeners();
  }

  void _scheduleRetry() {
    if (isSimulator) return;
    if (retryCount < maxRetries) {
      final delay = _retryDelays[retryCount];
      retryCount++;
      serviceState = ScoliaServiceState.reconnecting;
      _addLogEntry(UnknownMessage(null, '__RETRY_${retryCount}__'));
      _retryTimer = Timer(Duration(seconds: delay), () async {
        if (serviceState == ScoliaServiceState.reconnecting) {
          await _doConnect();
        }
      });
    } else {
      serviceState = ScoliaServiceState.failed;
      _addLogEntry(const UnknownMessage(null, '__FAILED__'));
      notifyListeners();
    }
  }

  void _startKeepAlive() {
    _stopKeepAlive();
    if (isSimulator) return;
    _keepAliveTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      if (_source is ScoliaConnection) {
        (_source as ScoliaConnection).send(ScoliaOutgoing.getSbcStatus());
      }
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  void _cancelTimers() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _stopKeepAlive();
  }

  void _cleanupSource() {
    _cancelTimers();
    _connSub?.cancel();
    _messageSub?.cancel();
    _source?.disconnect();
    _source = null;
  }

  /// Refresh source after settings change.
  void refresh() {
    serviceState = ScoliaServiceState.idle;
    retryCount = 0;
    _cleanupSource();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupSource();
    super.dispose();
  }
}
