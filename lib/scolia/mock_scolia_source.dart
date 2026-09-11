/// A simulator that behaves like a real Scolia board by emitting **real-format**
/// messages through the same parse path as the live client. Use it for unit
/// tests and for manual play without a physical board.
///
/// It exposes helper methods to script sequences (throw darts, takeout, status
/// changes) and feeds raw JSON frames through [ScoliaMessage.parse], so the
/// pipeline downstream is exercised exactly as it will be with the live board.
library;

import 'dart:async';

import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_event_source.dart';

class MockScoliaSource implements ScoliaEventSource {
  final _messageController = StreamController<ScoliaMessage>.broadcast();
  final _statusController = StreamController<BoardStatus>.broadcast();
  final _connController =
      StreamController<ScoliaConnectionState>.broadcast();

  BoardStatus _currentStatus = BoardStatus.offline;

  @override
  Stream<ScoliaMessage> get messages => _messageController.stream;

  @override
  Stream<BoardStatus> get status => _statusController.stream;

  @override
  Stream<ScoliaConnectionState> get connectionState => _connController.stream;

  @override
  BoardStatus get currentStatus => _currentStatus;

  @override
  Future<void> connect() async {
    _connController.add(ScoliaConnectionState.connecting);
    _connController.add(ScoliaConnectionState.connected);
    // Emulate the HELLO_CLIENT handshake: board Ready, phase Throw.
    emitRaw(
        '{"type":"HELLO_CLIENT","id":"mock-hello","payload":{"boardStatus":"Ready","boardPhase":"Throw","errorType":null}}');
  }

  @override
  Future<void> disconnect() async {
    _connController.add(ScoliaConnectionState.disconnected);
  }

  /// Feed a raw JSON frame exactly as the live board would send it.
  void emitRaw(String rawJson) {
    final msg = ScoliaMessage.parse(rawJson);
    if (msg is HelloClientMessage) {
      _currentStatus = msg.status;
      _statusController.add(msg.status);
    } else if (msg is SbcStatusMessage) {
      _currentStatus = msg.status;
      _statusController.add(msg.status);
    }
    _messageController.add(msg);
  }

  // ---- Convenience scripting helpers (build real-format frames) ----

  /// Emit a THROW_DETECTED with the given [sector] (e.g. "T20", "Bull", "None").
  void throwSector(String sector, {bool bounceout = false}) {
    emitRaw('{"type":"THROW_DETECTED","id":"mock-${_seq++}","payload":'
        '{"sector":"$sector","bounceout":$bounceout}}');
  }

  /// Emit TAKEOUT_STARTED.
  void takeoutStarted() {
    emitRaw('{"type":"TAKEOUT_STARTED","id":"mock-${_seq++}","payload":{}}');
  }

  /// Emit TAKEOUT_FINISHED (real takeout unless [falseTakeout]).
  void takeoutFinished({bool falseTakeout = false}) {
    emitRaw('{"type":"TAKEOUT_FINISHED","id":"mock-${_seq++}","payload":'
        '{"falseTakeout":$falseTakeout}}');
  }

  /// Emit a status change.
  void statusChanged(BoardStatus status, {BoardPhase? phase}) {
    final statusStr = _statusToString(status);
    final phaseStr = phase == null
        ? 'null'
        : '"${phase == BoardPhase.throwing ? 'Throw' : 'Takeout'}"';
    emitRaw('{"type":"SBC_STATUS_CHANGED","id":"mock-${_seq++}","payload":'
        '{"boardStatus":"$statusStr","boardPhase":$phaseStr,"errorType":null}}');
  }

  /// Convenience: throw three sectors then a real takeout (a full round).
  void playRound(List<String> sectors) {
    for (final s in sectors) {
      throwSector(s);
    }
    takeoutFinished();
  }

  int _seq = 0;

  static String _statusToString(BoardStatus s) {
    switch (s) {
      case BoardStatus.offline:
        return 'Offline';
      case BoardStatus.updating:
        return 'Updating';
      case BoardStatus.initializing:
        return 'Initializing';
      case BoardStatus.calibrating:
        return 'Calibrating';
      case BoardStatus.ready:
        return 'Ready';
      case BoardStatus.error:
        return 'Error';
    }
  }

  void dispose() {
    _messageController.close();
    _statusController.close();
    _connController.close();
  }
}
