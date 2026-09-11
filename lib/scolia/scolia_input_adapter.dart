/// Wires a [ScoliaEventSource] to a game controller.
///
/// It listens to the source's messages, drives a [TurnCollector] (handling
/// throws, takeout, and phase changes), and forwards each completed
/// [TurnResult] to the active [ScoliaController].
library;

import 'dart:async';

import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_controller.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/turn_collector.dart';

class ScoliaInputAdapter {
  ScoliaInputAdapter({
    required this.source,
    this.controller,
  }) {
    _collector = TurnCollector(onTurnComplete: _handleTurnComplete);
  }

  final ScoliaEventSource source;

  /// The controller currently receiving turns. Swap when entering a game.
  ScoliaController? controller;

  late final TurnCollector _collector;
  StreamSubscription<ScoliaMessage>? _sub;

  /// Begin listening to the source. Call [ScoliaEventSource.connect] separately.
  void start() {
    _collector.reset();
    _sub = source.messages.listen(_onMessage);
  }

  /// Stop listening. Does not disconnect the source.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Clear any buffered darts (e.g. on game entry).
  void resetTurn() => _collector.reset();

  void _onMessage(ScoliaMessage msg) {
    switch (msg) {
      case HelloClientMessage(:final phase):
      case SbcStatusMessage(:final phase):
        _collector.setPhase(phase);
      case ThrowDetectedMessage(:final detectedThrow):
        _collector.addThrow(detectedThrow);
      case TakeoutStartedMessage():
        _collector.onTakeoutStarted();
      case TakeoutFinishedMessage(:final falseTakeout):
        _collector.onTakeoutFinished(falseTakeout: falseTakeout);
      default:
        break;
    }
  }

  void _handleTurnComplete(TurnResult turn) {
    controller?.submitScoliaTurn(turn);
  }
}
