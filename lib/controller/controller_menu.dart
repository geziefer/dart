import 'dart:async';

import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_controller.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/scolia_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';

/// Controller of the main menu. In Scolia mode a dart thrown at number N
/// (any ring) starts the game no. N of the menu grid, exactly as tapping its
/// button would.
///
/// It listens to the global [ScoliaService] source itself (fed through
/// [configure] by a ProxyProvider), so the [Menu] widget stays stateless.
/// Unlike the in-game input it reacts to the first dart immediately — there
/// is no turn to collect.
class ControllerMenu extends ChangeNotifier implements ScoliaController {
  ControllerMenu({required this.navigatorKey}) {
    routeObserver = _MenuRouteObserver(this);
  }

  /// Key of the app's navigator; used to launch games without a [Menu] context.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Observer to register with the app's navigator so we know whether the
  /// menu (and not a game or dialog) is currently the visible route.
  late final NavigatorObserver routeObserver;

  bool _menuVisible = true;
  bool _scoliaActive = false;
  bool _awaitingTakeout = false;

  /// True after a dart started a game, until that dart is taken out (or the
  /// wait is cancelled). The started game must ignore darts meanwhile.
  bool get awaitingTakeout => _awaitingTakeout;

  void cancelTakeoutWait() {
    if (!_awaitingTakeout) return;
    _awaitingTakeout = false;
    notifyListeners();
  }

  void _setMenuVisible(bool visible) {
    _menuVisible = visible;
    // Back in the menu: nothing to wait for any more (no notify needed, the
    // gate is gone with its route).
    if (visible) _awaitingTakeout = false;
  }
  ScoliaEventSource? _source;
  StreamSubscription<ScoliaMessage>? _sub;

  /// Update input mode and Scolia service. Called by the ProxyProvider on every
  /// change of either; cheap and idempotent.
  void configure({required bool scoliaActive, ScoliaService? service}) {
    _scoliaActive = scoliaActive;
    final source = scoliaActive ? service?.source : null;
    if (!identical(source, _source)) {
      _sub?.cancel();
      _source = source;
      _sub = source?.messages.listen(_onMessage);
    }
    // Switch off / board gone: never keep a game waiting for a takeout.
    if (_awaitingTakeout && source == null) {
      scheduleMicrotask(cancelTakeoutWait);
    }
    // The connection is otherwise only opened by the in-game dartboard. Open
    // it from the menu too (deferred: we may be inside a build phase).
    if (scoliaActive &&
        service != null &&
        !service.isSimulator &&
        service.serviceState == ScoliaServiceState.idle) {
      scheduleMicrotask(service.connect);
    }
  }

  void _onMessage(ScoliaMessage msg) {
    switch (msg) {
      case ThrowDetectedMessage(:final detectedThrow):
        onThrow(detectedThrow);
      case TakeoutFinishedMessage(:final falseTakeout):
        if (!falseTakeout) cancelTakeoutWait();
      default:
        break;
    }
  }

  /// React to a single dart. Returns true if it launched a game.
  bool onThrow(DetectedThrow t) {
    if (!_scoliaActive || !_menuVisible) return false;
    final item = Menu.gameForThrow(t);
    if (item == null) return false;
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) return false;
    _menuVisible = false; // ignore the remaining darts of this turn
    _awaitingTakeout = true; // the game waits until this dart is removed
    Menu.launchGame(context, item, navigator: navigator, awaitTakeout: true);
    return true;
  }

  /// Same selection from a completed turn (the generic [ScoliaController]
  /// contract): the first dart that picks a game wins.
  @override
  void submitScoliaTurn(TurnResult turn) {
    for (final t in turn.darts) {
      if (onThrow(t)) return;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Tracks whether the first route (the menu) is the one on top.
class _MenuRouteObserver extends NavigatorObserver {
  _MenuRouteObserver(this._controller);

  final ControllerMenu _controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _controller._setMenuVisible(route.isFirst);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _controller._setMenuVisible(previousRoute?.isFirst ?? true);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _controller._setMenuVisible(newRoute?.isFirst ?? false);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _controller._setMenuVisible(previousRoute?.isFirst ?? true);
}
