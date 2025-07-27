import 'dart:async';
import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerSpeedBull extends ControllerBase
    implements MenuitemController, NumpadController {
  static final ControllerSpeedBull _instance = ControllerSpeedBull._private();

  // singleton
  ControllerSpeedBull._private();

  factory ControllerSpeedBull() {
    return _instance;
  }

  late MenuItem item; // item which created the controller

  List<int> rounds = <int>[]; // list of round numbers
  List<int> hits = <int>[]; // list of hits per round
  int totalHits = 0; // total number of bull hits
  int round = 1; // current round number
  bool gameStarted = false; // flag to track if game has started
  bool gameEnded = false; // flag to track if game has ended
  bool lastThrowAllowed = false; // flag for final throw after timer ends

  // Timer related
  late int gameDurationSeconds; // configurable game duration
  int remainingSeconds = 0; // remaining time
  Timer? gameTimer; // timer instance

  @override
  void init(MenuItem item) {
    this.item = item;

    // Get duration from params, default to 60 seconds
    gameDurationSeconds = item.params['duration'] ?? 60;

    rounds = <int>[1]; // start with round 1
    hits = <int>[0]; // start with empty hits (0 = empty display)
    totalHits = 0;
    round = 1;
    gameStarted = false;
    gameEnded = false;
    lastThrowAllowed = false;
    remainingSeconds = gameDurationSeconds;

    // Cancel any existing timer
    gameTimer?.cancel();
    gameTimer = null;
  }

  void startGame() {
    if (gameStarted || gameEnded) return;

    gameStarted = true;
    remainingSeconds = gameDurationSeconds;

    // Start the countdown timer
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      notifyListeners();

      if (remainingSeconds <= 0) {
        timer.cancel();
        lastThrowAllowed = true;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (rounds.length > 1 && !gameEnded && !lastThrowAllowed) {
        // get previous round data
        int previousHits = hits[hits.length - 2];

        // remove last entries (current row)
        rounds.removeLast();
        hits.removeLast();

        // restore previous state
        round--;
        totalHits -= previousHits;

        // make current row empty again
        hits[hits.length - 1] = 0;

        notifyListeners();
      }
      return;
    }

    // game not started yet
    if (!gameStarted) {
      return;
    }

    // game already ended (and last throw was used)
    if (gameEnded) {
      return;
    }

    // return button pressed (same as 0 - no hits)
    int bullHits = value;
    if (value == -1) {
      bullHits = 0;
    }

    // validate input (0-3 hits allowed)
    if (bullHits < 0 || bullHits > 3) {
      return;
    }

    // record the round (complete current row)
    hits[hits.length - 1] = bullHits;
    totalHits += bullHits;

    // check if this was the last allowed throw
    if (lastThrowAllowed) {
      gameEnded = true;
      gameTimer?.cancel();
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSummaryDialog(context);
      });
      return;
    }

    // advance to next round (add next row with EMPTY values)
    round++;
    rounds.add(round);
    hits.add(0); // add EMPTY hits (0 means empty display)

    notifyListeners();
  }

  @override
  String getInput() {
    return "";
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in Speed Bull
  }

  String getTimerDisplay() {
    return remainingSeconds.toString();
  }

  Map getCurrentStats() {
    double averageHitsPerRound = 0.0;
    int completedRounds = round - 1; // exclude current empty round
    if (completedRounds > 0) {
      averageHitsPerRound = totalHits / completedRounds;
    }

    return {
      'rounds': completedRounds,
      'totalHits': totalHits,
      'average': averageHitsPerRound.toStringAsFixed(1),
    };
  }

  String getStats() {
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordHits = storage.read('recordHits') ?? 0;
    double overallAverage = storage.read('overallAverage') ?? 0;

    return '#S: $numberGames  ♛P: $recordHits  ØP: ${overallAverage.toStringAsFixed(1)}';
  }

  void _showSummaryDialog(BuildContext context) {
    // save stats to device
    _updateGameStats();

    int completedRounds = round - 1; // exclude current empty round
    double averageHitsPerRound = 0.0;
    if (completedRounds > 0) {
      averageHitsPerRound = totalHits / completedRounds;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(
          lines: [
            SummaryLine('Runden gespielt', '$completedRounds'),
            SummaryLine('Bull Treffer', '$totalHits'),
            SummaryLine(
                'Ø Treffer/Runde', averageHitsPerRound.toStringAsFixed(1),
                emphasized: true),
          ],
        );
      },
    );
  }

  void _updateGameStats() {
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int totalHitsAllGames = storage.read('totalHitsAllGames') ?? 0;
    int totalRoundsAllGames = storage.read('totalRoundsAllGames') ?? 0;
    int recordHits = storage.read('recordHits') ?? 0;

    int completedRounds = round - 1; // exclude current empty round

    storage.write('numberGames', numberGames + 1);
    storage.write('totalHitsAllGames', totalHitsAllGames + totalHits);
    storage.write('totalRoundsAllGames', totalRoundsAllGames + completedRounds);

    if (recordHits == 0 || totalHits > recordHits) {
      storage.write('recordHits', totalHits);
    }

    // calculate overall average hits per round
    double overallAverage = 0.0;
    int newTotalRounds = totalRoundsAllGames + completedRounds;
    if (newTotalRounds > 0) {
      overallAverage = (totalHitsAllGames + totalHits) / newTotalRounds;
    }
    storage.write('overallAverage', overallAverage);
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
}
