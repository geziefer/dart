/// App-level Scolia service: owns the active event source (real or mock),
/// manages connect/disconnect, and exposes the current source to the widget
/// tree via Provider. Game views read [source] and [isSimulator] from here
/// instead of creating their own connections.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dart/scolia/mock_scolia_source.dart';
import 'package:dart/scolia/scolia_connection.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/scolia_settings.dart';

class ScoliaService extends ChangeNotifier {
  ScoliaService({required this.settings}) {
    _rebuild();
  }

  final ScoliaSettings settings;

  ScoliaEventSource? _source;
  bool _connected = false;
  StreamSubscription<ScoliaConnectionState>? _stateSub;
  Timer? _reconnectTimer;

  /// The active event source (mock or real), or null if not yet started.
  ScoliaEventSource? get source => _source;

  /// True when the simulator mock is active (not the real board).
  bool get isSimulator => settings.simulatorEnabled || !settings.isConfigured;

  /// Rebuild the source based on current settings (call after settings change).
  void _rebuild() {
    _reconnectTimer?.cancel();
    _stateSub?.cancel();
    _source?.disconnect();
    _source = isSimulator
        ? MockScoliaSource()
        : ScoliaConnection(
            serialNumber: settings.serialNumber,
            accessToken: settings.accessToken,
          );
    _connected = false;
    // Subscribe to connection state for auto-reconnect.
    _stateSub = _source!.connectionState.listen(_onConnectionState);
    notifyListeners();
  }

  void _onConnectionState(ScoliaConnectionState state) {
    if (isSimulator) return; // no reconnect needed for mock
    if (state == ScoliaConnectionState.disconnected ||
        state == ScoliaConnectionState.error) {
      _connected = false;
      // Auto-reconnect after 3 seconds.
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (!isSimulator) connect();
      });
    } else if (state == ScoliaConnectionState.connected) {
      _reconnectTimer?.cancel();
    }
  }

  /// Connect (or reconnect) the active source. Called when a game opens.
  Future<void> connect() async {
    if (_connected) return;
    // For real connections, rebuild the channel (old one is closed).
    if (!isSimulator) {
      _stateSub?.cancel();
      _source = ScoliaConnection(
        serialNumber: settings.serialNumber,
        accessToken: settings.accessToken,
      );
      _stateSub = _source!.connectionState.listen(_onConnectionState);
    }
    await _source?.connect();
    _connected = true;
    notifyListeners();
  }

  /// Disconnect the active source.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _source?.disconnect();
    _connected = false;
  }

  /// Refresh the source after settings change (e.g. simulator switch toggled).
  void refresh() {
    _rebuild();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _stateSub?.cancel();
    _source?.disconnect();
    super.dispose();
  }
}
