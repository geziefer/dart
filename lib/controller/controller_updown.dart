import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:flutter/material.dart';
class ControllerUpDown extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerUpDown({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerUpDown.create() {
    return ControllerUpDown();
  }

  // Factory for testing with injected storage
  factory ControllerUpDown.forTesting(GetStorage storage) {
    return ControllerUpDown(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<int> rounds = <int>[]; // round numbers
  List<int> targets = <int>[]; // target values for each round
  List<bool> results = <bool>[]; // success/failure results
  int currentRound = 1; // current round (1-13)
  int currentTarget = 50; // current target value
  int successCount = 0; // number of successful rounds
  int highestTarget = 50; // highest target reached in current game

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    rounds = <int>[1];
    targets = <int>[50];
    results = <bool>[];
    currentRound = 1;
    currentTarget = 50;
    successCount = 0;
    highestTarget = 50;
    notifyListeners();
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // undo button pressed
    if (value == -2) {
      if (results.isNotEmpty) {
        bool lastResult = results.removeLast();
        if (lastResult) {
          successCount--;
        }

        // Recalculate target based on previous results
        currentTarget = 50;
        for (bool result in results) {
          if (result) {
            currentTarget += 10;
          } else {
            currentTarget -= 1;
          }
        }

        // Update highest target
        highestTarget = 50;
        int tempTarget = 50;
        for (bool result in results) {
          if (result) {
            tempTarget += 10;
          } else {
            tempTarget -= 1;
          }
          if (tempTarget > highestTarget) {
            highestTarget = tempTarget;
          }
        }
        if (currentTarget > highestTarget) {
          highestTarget = currentTarget;
        }

        currentRound--;
        rounds.removeLast();
        targets.removeLast();
        notifyListeners();
      }
      return;
    }

    // handle yes/no input (0 = no/fail, 1 = yes/success)
    if (value == 0 || value == 1) {
      bool success = value == 1;
      results.add(success);

      if (success) {
        successCount++;
      }

      // Calculate next target
      int nextTarget = currentTarget;
      if (success) {
        nextTarget += 10;
      } else {
        nextTarget -= 1;
      }

      // Update highest target if current target is higher
      if (currentTarget > highestTarget) {
        highestTarget = currentTarget;
      }

      // Move to next round if not finished
      if (currentRound < 13) {
        currentRound++;
        currentTarget = nextTarget;
        rounds.add(currentRound);
        targets.add(currentTarget);

        // Update highest target for new target
        if (currentTarget > highestTarget) {
          highestTarget = currentTarget;
        }
      }

      notifyListeners();

      // check if game is finished (all 13 rounds completed)
      if (results.length == 13) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          triggerGameEnd();
        });
      }
    }
  }


  @override
  List<SummaryLine> createSummaryLines() {
    double averageSuccesses = successCount / 13.0;
    int lastTarget = targets.isNotEmpty ? targets.last : 50;

    return [
      SummaryService.createValueLine('Checks', successCount, emphasized: true),
      SummaryService.createAverageLine('Durchschnitt Checks', averageSuccesses),
      SummaryService.createValueLine('Letztes Ziel', lastTarget),
      SummaryService.createValueLine('Höchstes Ziel', highestTarget),
    ];
  }

  @override
  String getGameTitle() => 'Up Down';

  @override
  void updateSpecificStats() {
    double averageSuccesses = successCount / 13.0;

    // Update cumulative stats
    int totalSuccesses =
        statsService.getStat<int>('totalSuccesses', defaultValue: 0)!;
    statsService.updateStats({'totalSuccesses': totalSuccesses + successCount});

    // Update records
    statsService.updateRecord<int>('recordSuccesses', successCount);
    statsService.updateRecord<int>('recordHighestTarget', highestTarget);

    // Update long-term average
    statsService.updateLongTermAverage('longtermAverage', averageSuccesses);
  }

  String getCurrentRounds() {
    List<String> displayRounds = [];
    // Show completed rounds plus current round (if not finished)
    int roundsToShow =
        results.length < 13 ? results.length + 1 : results.length;
    // Safety check: don't exceed the actual rounds list length
    roundsToShow = roundsToShow > rounds.length ? rounds.length : roundsToShow;
    for (int i = 0; i < roundsToShow; i++) {
      displayRounds.add('${rounds[i]}');
    }
    return createMultilineString(displayRounds, [], '', '', [], 5, false);
  }

  String getCurrentTargets() {
    List<String> displayTargets = [];
    // Show completed targets plus current target (if not finished)
    int targetsToShow =
        results.length < 13 ? results.length + 1 : results.length;
    // Safety check: don't exceed the actual targets list length
    targetsToShow =
        targetsToShow > targets.length ? targets.length : targetsToShow;
    for (int i = 0; i < targetsToShow; i++) {
      displayTargets.add('${targets[i]}');
    }
    return createMultilineString(displayTargets, [], '', '', [], 5, false);
  }

  String getCurrentResults() {
    List<String> displayResults = [];
    // Show results for completed rounds only
    for (int i = 0; i < results.length; i++) {
      displayResults.add(results[i] ? '✅' : '❌');
    }
    // Add empty string for current round if game not finished
    if (results.length < 13) {
      displayResults.add('');
    }
    return createMultilineString(displayResults, [], '', '', [], 5, false);
  }

  @override
  bool isButtonDisabled(int value) {
    // Game finished, disable all input
    if (results.length >= 13) return true;

    // Undo button disabled if no results to undo
    if (value == -2) return results.isEmpty;

    // Allow yes/no buttons when game is not finished
    if (value == 0 || value == 1) return false;

    return true; // all other buttons disabled
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  String getInput() {
    return ''; // Keep input section empty for this game
  }

  Map getCurrentStats() {
    double currentAverage =
        results.isNotEmpty ? successCount / results.length : 0.0;

    return {
      'round': currentRound,
      'target': currentTarget,
      'successes': successCount,
      'averageSuccess': currentAverage,
    };
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordHighestTarget =
        statsService.getStat<int>('recordHighestTarget', defaultValue: 50)!;
    int recordSuccesses =
        statsService.getStat<int>('recordSuccesses', defaultValue: 0)!;
    double longtermAverage =
        statsService.getStat<double>('longtermAverage', defaultValue: 0.0)!;

    String baseStats = formatStatsString(
      numberGames: numberGames,
      records: {
        'Z': recordHighestTarget, // Record: Highest target
        'C': recordSuccesses, // Record: Checks
      },
      averages: {
        'C': longtermAverage, // Average: Checks
      },
    );
    return baseStats;
  }
}
