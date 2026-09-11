/// App-level Scolia service: owns the active event source (real or mock),
/// manages connect/disconnect, and exposes the current source to the widget
/// tree via Provider. Game views read [source] and [isSimulator] from here
/// instead of creating their own connections.
library;

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

  /// The active event source (mock or real), or null if not yet started.
  ScoliaEventSource? get source => _source;

  /// True when the simulator mock is active (not the real board).
  bool get isSimulator => settings.simulatorEnabled || !settings.isConfigured;

  /// Rebuild the source based on current settings (call after settings change).
  void _rebuild() {
    _source?.disconnect();
    _source = isSimulator
        ? MockScoliaSource()
        : ScoliaConnection(
            serialNumber: settings.serialNumber,
            accessToken: settings.accessToken,
          );
    _connected = false;
    notifyListeners();
  }

  /// Connect (or reconnect) the active source. Called when a game opens.
  Future<void> connect() async {
    if (_connected) return;
    await _source?.connect();
    _connected = true;
  }

  /// Disconnect the active source. Called when a game closes.
  Future<void> disconnect() async {
    await _source?.disconnect();
    _connected = false;
  }

  /// Refresh the source after settings change (e.g. simulator switch toggled).
  void refresh() {
    _rebuild();
  }

  @override
  void dispose() {
    _source?.disconnect();
    super.dispose();
  }
}
