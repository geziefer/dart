import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class ControllerBobs27 extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerBobs27({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerBobs27.create() {
    return ControllerBobs27();
  }

  // Factory for testing with injected storage
  factory ControllerBobs27.forTesting(GetStorage storage) {
    return ControllerBobs27(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<String> targets = <String>[]; // list of targets (1, 2, ..., 20, B)
  List<int> roundScores = <int>[]; // list of scores per round
  List<int> totalScores = <int>[]; // list of cumulative scores
  int currentTargetIndex = 0; // current target index (0-20)
  int totalScore = 27; // total score (starts with 27)
  int successfulRounds = 0; // number of successful rounds (hits > 0)
  int round = 1; // current round number
  bool gameEnded = false; // flag to track if game has ended
  bool gameWon = false; // flag to track if game was won

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    targets = <String>['1']; // start with target 1
    roundScores = <int>[0]; // start with empty round score (0 = empty display)
    totalScores = <int>[27]; // start with initial score of 27
    currentTargetIndex = 0;
    totalScore = 27;
    successfulRounds = 0;
    round = 1;
    gameEnded = false;
    gameWon = false;
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // undo button pressed
    if (value == -2) {
      if (roundScores.length > 1 && !gameEnded) {
        // need at least 2 entries (current + previous)
        round--;
        currentTargetIndex--;

        // remove last entries (current row)
        targets.removeLast();
        roundScores.removeLast();
        totalScores.removeLast();

        // restore previous round score and total
        int previousRoundScore = roundScores[roundScores.length - 1];
        totalScore -= previousRoundScore; // undo previous calculation
        roundScores[roundScores.length - 1] = 0; // make current row empty again

        // If we're back to round 1, restore the initial score of 27; otherwise set to 0
        if (round == 1) {
          totalScores[totalScores.length - 1] = 27; // restore initial score
        } else {
          totalScores[totalScores.length - 1] =
              0; // make current total empty again
        }

        // adjust successful rounds if previous round was successful
        if (previousRoundScore > 0) {
          successfulRounds--;
        }

        notifyListeners();
      }
      return;
    }

    // game already ended
    if (gameEnded) {
      return;
    }

    // return button pressed (same as 0 - no hits)
    int hits = value;
    if (value == -1) {
      hits = 0;
    }

    // validate input (0-3 hits allowed)
    if (hits < 0 || hits > 3) {
      return;
    }

    // process the round
    int currentTarget = _getCurrentTargetNumber();
    int roundScore = _calculateScore(currentTarget, hits);

    // record the round (complete current row)
    roundScores[roundScores.length - 1] =
        roundScore; // overwrite current round score
    totalScore += roundScore;
    totalScores[totalScores.length - 1] = totalScore; // overwrite current total

    // track successful rounds
    if (hits > 0) {
      successfulRounds++;
    }

    // check game end conditions
    if (totalScore <= 0) {
      gameEnded = true;
      gameWon = false;
    } else if (currentTargetIndex >= 20) {
      // completed all targets including bull
      gameEnded = true;
      gameWon = true;
    } else {
      // advance to next target (add next row with EMPTY values)
      currentTargetIndex++;
      targets.add(_getCurrentTargetDisplay());
      roundScores.add(0); // add EMPTY round score (0 means empty display)
      totalScores.add(0); // add EMPTY total (0 means empty display)
      round++;
    }

    notifyListeners();

    // show summary if game ended
    if (gameEnded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        triggerGameEnd();
      });
    }
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
    return false; // no buttons disabled in Bob's 27
  }

  int _getCurrentTargetNumber() {
    if (currentTargetIndex < 20) {
      return currentTargetIndex + 1; // targets 1-20
    } else {
      return 21; // bull
    }
  }

  String _getCurrentTargetDisplay() {
    int target = _getCurrentTargetNumber();
    if (target == 21) {
      return "B";
    } else {
      return target.toString(); // just the number, no D prefix
    }
  }

  int _calculateScore(int target, int hits) {
    int doubleValue;
    if (target == 21) {
      // bull
      doubleValue = 50;
    } else {
      doubleValue = target * 2;
    }

    if (hits > 0) {
      return hits * doubleValue; // positive score for hits
    } else {
      return -doubleValue; // negative score for miss
    }
  }

  String getCurrentTargets() {
    return createMultilineString(targets, [], '', '', [], 5, false);
  }

  String getCurrentRoundScores() {
    // Convert roundScores to display format - show empty for 0 values
    List<String> displayScores = [];
    for (int i = 0; i < roundScores.length; i++) {
      if (roundScores[i] != 0) {
        displayScores.add(roundScores[i].toString());
      } else {
        displayScores.add(''); // empty display for 0 values
      }
    }
    return createMultilineString(displayScores, [], '', '', [], 5, false);
  }

  String getCurrentTotalScores() {
    // Convert totalScores to display format - show empty for 0 values except first
    List<String> displayScores = [];
    for (int i = 0; i < totalScores.length; i++) {
      if (i == 0 || totalScores[i] != 0) {
        displayScores.add(totalScores[i].toString());
      } else {
        displayScores.add(''); // empty display for 0 values
      }
    }
    return createMultilineString(displayScores, [], '', '', [], 5, false);
  }

  Map getCurrentStats() {
    return {
      'successful': successfulRounds,
      'total': totalScore,
      'average': _getAverageScore(),
    };
  }

  String _getAverageScore() {
    if (round == 1) {
      return "0.0";
    }
    double avg = (totalScore - 27) / (round - 1); // exclude starting score
    return avg.toStringAsFixed(1);
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordSuccessful =
        statsService.getStat<int>('recordSuccessful', defaultValue: 0)!;
    int recordTotal =
        statsService.getStat<int>('recordTotal', defaultValue: 0)!;
    double longtermAverage =
        statsService.getStat<double>('longtermAverage', defaultValue: 0.0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'E': recordSuccessful, // Erfolgreiche Runden
        'P': recordTotal, // Punkte
      },
      averages: {
        'P': longtermAverage, // Durchschnittspunkte
      },
    );
  }

  @override
  List<SummaryLine> createSummaryLines() {
    return [
      SummaryService.createCompletionLine('Bob\'s 27', gameWon),
      SummaryService.createValueLine('Erfolgreiche Runden', successfulRounds),
      SummaryService.createValueLine('Gesamtpunkte', totalScore),
      SummaryService.createValueLine('Punkte/Runde', _getAverageScore(),
          emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Bob\'s 27';

  @override
  void updateSpecificStats() {
    double currentAverage = double.parse(_getAverageScore());

    // Update records using StatsService
    statsService.updateRecord<int>('recordSuccessful', successfulRounds);
    statsService.updateRecord<int>('recordTotal', totalScore);

    // Update long-term average
    statsService.updateLongTermAverage('longtermAverage', currentAverage);
  }
}
