import 'dart:async';
import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:provider/provider.dart';

class ControllerSpeedBull extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerSpeedBull({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerSpeedBull.create() {
    return ControllerSpeedBull();
  }

  // Factory for testing with injected storage
  factory ControllerSpeedBull.forTesting(GetStorage storage) {
    return ControllerSpeedBull(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<int> rounds = <int>[]; // list of round numbers
  List<int> hits = <int>[]; // list of hits per round
  int totalHits = 0; // total number of bull hits
  int round = 1; // current round number
  bool gameStarted = false; // flag to track if game has started
  bool gameEnded = false; // flag to track if game has ended
  bool lastThrowAllowed = false; // flag for final throw after timer ends

  // Timer related
  int gameDurationSeconds = 60; // configurable game duration
  int remainingSeconds = 0; // remaining time
  Timer? gameTimer; // timer instance

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

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

  @override
  void initFromProvider(BuildContext context, MenuItem item) {
    Provider.of<ControllerSpeedBull>(context, listen: false).init(item);
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
    int numberGames = statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordHits = statsService.getStat<int>('recordHits', defaultValue: 0)!;
    double overallAverage = statsService.getStat<double>('overallAverage', defaultValue: 0.0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'P': recordHits,        // Punkte/Hits
      },
      averages: {
        'P': overallAverage,    // Durchschnittspunkte
      },
    );
  }

  void _showSummaryDialog(BuildContext context) {
    showSummaryDialog(context);
  }

  @override
  List<SummaryLine> createSummaryLines() {
    int completedRounds = round - 1; // exclude current empty round
    double averageHitsPerRound = 0.0;
    if (completedRounds > 0) {
      averageHitsPerRound = totalHits / completedRounds;
    }
    
    return [
      SummaryService.createValueLine('Runden gespielt', completedRounds),
      SummaryService.createValueLine('Bull Treffer', totalHits),
      SummaryService.createAverageLine('Ø Treffer/Runde', averageHitsPerRound, emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Speed Bull';

  @override
  void updateSpecificStats() {
    int completedRounds = round - 1; // exclude current empty round
    
    // Update cumulative stats
    int totalHitsAllGames = statsService.getStat<int>('totalHitsAllGames', defaultValue: 0)!;
    int totalRoundsAllGames = statsService.getStat<int>('totalRoundsAllGames', defaultValue: 0)!;
    
    statsService.updateStats({
      'totalHitsAllGames': totalHitsAllGames + totalHits,
      'totalRoundsAllGames': totalRoundsAllGames + completedRounds,
    });
    
    // Update records
    statsService.updateRecord<int>('recordHits', totalHits);
    
    // Calculate and store overall average
    double overallAverage = 0.0;
    int newTotalRounds = totalRoundsAllGames + completedRounds;
    if (newTotalRounds > 0) {
      overallAverage = (totalHitsAllGames + totalHits) / newTotalRounds;
    }
    statsService.updateStats({'overallAverage': overallAverage});
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
}
