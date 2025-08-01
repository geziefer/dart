import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:flutter/material.dart';
class ControllerCheck121 extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerCheck121({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerCheck121.create() {
    return ControllerCheck121();
  }

  // Factory for testing with injected storage
  factory ControllerCheck121.forTesting(GetStorage storage) {
    return ControllerCheck121(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<int> rounds = <int>[]; // list of round numbers
  List<int> targets = <int>[]; // list of current targets
  List<int> attempts = <int>[]; // list of attempts (1-3 or 0 for miss)
  List<int> savePoints =
      <int>[]; // list of save points for each round (for undo)
  int currentTarget = 121; // current target score
  int savePoint = 121; // current save point
  int successfulRounds = 0; // number of successful rounds
  int missCount = 0; // number of misses (0 attempts)
  int highestTarget = 121; // highest target reached in this session
  int round = 1; // current round number
  bool gameEnded = false; // flag to track if game has ended

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    rounds = <int>[1]; // start with round 1
    targets = <int>[121]; // start with target 121
    attempts = <int>[0]; // start with empty attempts (0 = empty display)
    savePoints = <int>[121]; // start with save point 121
    currentTarget = 121;
    savePoint = 121;
    successfulRounds = 0;
    missCount = 0;
    highestTarget = 121;
    round = 1;
    gameEnded = false;
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // undo button pressed
    if (value == -2) {
      if (rounds.length > 1 && !gameEnded) {
        // need at least 2 entries (current + previous)
        // get previous round data
        int previousAttempts = attempts[attempts.length - 2];
        int previousTarget = targets[targets.length - 2];
        int previousSavePoint = savePoints[savePoints.length - 2];

        // remove last entries (current row)
        rounds.removeLast();
        targets.removeLast();
        attempts.removeLast();
        savePoints.removeLast();

        // restore previous state
        round--;
        currentTarget = previousTarget;
        savePoint = previousSavePoint;

        // recalculate highest target
        highestTarget = 121;
        for (int target in targets) {
          if (target > highestTarget) {
            highestTarget = target;
          }
        }

        // adjust counters based on previous round
        if (previousAttempts > 0) {
          successfulRounds--;
        } else {
          missCount--;
        }

        // make current row empty again
        attempts[attempts.length - 1] = 0;

        notifyListeners();
      }
      return;
    }

    // game already ended
    if (gameEnded) {
      return;
    }

    // return button pressed (same as 0 - miss)
    int attemptsUsed = value;
    if (value == -1) {
      attemptsUsed = 0;
    }

    // validate input (0-3 attempts allowed)
    if (attemptsUsed < 0 || attemptsUsed > 3) {
      return;
    }

    // record the round (complete current row)
    attempts[attempts.length - 1] = attemptsUsed;

    // process the result
    if (attemptsUsed == 0) {
      // miss - fall back to save point
      missCount++;
      currentTarget = savePoint;

      // check if game ended (10th miss)
      if (missCount >= 10) {
        gameEnded = true;
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          triggerGameEnd();
        });
        return;
      }
    } else {
      // successful finish
      successfulRounds++;

      // if finished in 1 attempt, update save point
      if (attemptsUsed == 1) {
        savePoint = currentTarget + 1;
      }

      // next target is +1
      currentTarget++;

      // update highest target if needed
      if (currentTarget > highestTarget) {
        highestTarget = currentTarget;
      }
    }

    // advance to next round (add next row with EMPTY values)
    round++;
    rounds.add(round);
    targets.add(currentTarget);
    attempts.add(0); // add EMPTY attempts (0 means empty display)
    savePoints.add(savePoint); // store current save point for undo

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
    return false; // no buttons disabled in Check 121
  }

  String getCurrentRounds() {
    return createMultilineString(rounds, [], '', '', [], 5, false);
  }

  String getCurrentTargets() {
    return createMultilineString(targets, [], '', '', [], 5, false);
  }

  String getCurrentAttempts() {
    // Convert attempts to display format - show "-" for 0 values (misses)
    List<String> displayAttempts = [];
    for (int i = 0; i < attempts.length; i++) {
      if (attempts[i] > 0) {
        displayAttempts.add(attempts[i].toString());
      } else if (attempts[i] == 0 && i < attempts.length - 1) {
        // Show "-" for completed rounds with 0 attempts (misses)
        displayAttempts.add('X');
      } else {
        displayAttempts.add(''); // empty display for current empty row
      }
    }
    return createMultilineString(displayAttempts, [], '', '', [], 5, false);
  }

  Map getCurrentStats() {
    return {
      'target': currentTarget,
      'successful': successfulRounds,
      'misses': missCount,
      'savePoint': savePoint,
      'average': _getAverageAttempts(),
    };
  }

  String _getAverageAttempts() {
    // Calculate percentage: successful rounds / total rounds attempted
    int totalRoundsAttempted = round - 1; // exclude current empty round
    if (totalRoundsAttempted == 0) {
      return "0.0";
    }

    double percentage = successfulRounds / totalRoundsAttempted;
    return percentage.toStringAsFixed(1);
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int totalSuccessfulRounds =
        statsService.getStat<int>('totalSuccessfulRounds', defaultValue: 0)!;
    int totalRoundsPlayed =
        statsService.getStat<int>('totalRoundsPlayed', defaultValue: 0)!;
    int highestTarget =
        statsService.getStat<int>('highestTarget', defaultValue: 0)!;
    int highestSavePoint =
        statsService.getStat<int>('highestSavePoint', defaultValue: 0)!;

    // Calculate percentage of successful rounds across all games
    double averageSuccessPercentage = 0.0;
    if (totalRoundsPlayed > 0) {
      averageSuccessPercentage = totalSuccessfulRounds / totalRoundsPlayed;
    }

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'C': totalSuccessfulRounds, // Checks
        'Z': highestTarget, // Ziel
        'S': highestSavePoint, // Safepoint
      },
      averages: {
        'C': averageSuccessPercentage, // Checks
      },
    );
  }


  @override
  List<SummaryLine> createSummaryLines() {
    return [
      SummaryService.createValueLine('Gespielte Runden', round - 1),
      SummaryService.createValueLine('Höchstes Ziel', highestTarget),
      SummaryService.createValueLine('Letzter Safepoint', savePoint),
      SummaryService.createValueLine(
          'Ø Erfolgreiche Runden', _getAverageAttempts(),
          emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Check 121';

  @override
  void updateSpecificStats() {
    int currentRoundsPlayed = round - 1; // exclude current empty round

    // Update cumulative stats
    int totalSuccessfulRounds =
        statsService.getStat<int>('totalSuccessfulRounds', defaultValue: 0)!;
    int totalRoundsPlayed =
        statsService.getStat<int>('totalRoundsPlayed', defaultValue: 0)!;

    statsService.updateStats({
      'totalSuccessfulRounds': totalSuccessfulRounds + successfulRounds,
      'totalRoundsPlayed': totalRoundsPlayed + currentRoundsPlayed,
    });

    // Update records
    statsService.updateRecord<int>('highestTarget', highestTarget);
    statsService.updateRecord<int>('highestSavePoint', savePoint);
  }
}
