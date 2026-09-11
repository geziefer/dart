/// Common interface for a source of Scolia events, implemented by both the
/// real WebSocket client ([ScoliaConnection]) and the [MockScoliaSource]
/// simulator. The rest of the app (adapter, UI) depends only on this.
library;

import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';

/// High-level connection state of the source (distinct from board status).
enum ScoliaConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

abstract class ScoliaEventSource {
  /// Stream of every parsed incoming message (typed). Consumers can pattern
  /// match on the sealed [ScoliaMessage] hierarchy.
  Stream<ScoliaMessage> get messages;

  /// Convenience stream of the current board status as it changes.
  Stream<BoardStatus> get status;

  /// High-level connection state of this source.
  Stream<ScoliaConnectionState> get connectionState;

  /// The most recently known board status (or offline if never received).
  BoardStatus get currentStatus;

  /// Open the connection (or start the simulator).
  Future<void> connect();

  /// Close the connection (or stop the simulator).
  Future<void> disconnect();
}
