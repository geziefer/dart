import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class Controller10Up1Down extends ControllerBase
    implements MenuitemController, NumpadController {
  static final Controller10Up1Down _instance = Controller10Up1Down._private();

  // singleton
  Controller10Up1Down._private();

  factory Controller10Up1Down() {
    return _instance;
  }

  late MenuItem item; // item which created the controller

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
  void pressNumpadButton(BuildContext context, int value) {
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
          _showSummaryDialog(context);
        });
      }
    }
  }

  void _showSummaryDialog(BuildContext context) {
    // save stats to device
    _updateGameStats();

    double averageSuccesses = successCount / 13.0;
    int lastTarget = targets.isNotEmpty ? targets.last : 50;

    List<SummaryLine> summaryLines = [
      SummaryLine('Checks', '$successCount', emphasized: true),
      SummaryLine('Durchschnitt Checks', averageSuccesses.toStringAsFixed(1)),
      SummaryLine('Letztes Ziel', '$lastTarget'),
      SummaryLine('Höchstes Ziel', '$highestTarget'),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(lines: summaryLines);
      },
    );
  }

  void _updateGameStats() {
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int totalSuccesses = storage.read('totalSuccesses') ?? 0;
    int recordTarget = storage.read('recordTarget') ?? 50;
    int recordSuccesses = storage.read('recordSuccesses') ?? 0;
    double recordAverage = storage.read('recordAverage') ?? 0.0;
    double longtermAverage = storage.read('longtermAverage') ?? 0.0;

    double gameAverage = successCount / 13.0;

    storage.write('numberGames', numberGames + 1);
    storage.write('totalSuccesses', totalSuccesses + successCount);

    if (highestTarget > recordTarget) {
      storage.write('recordTarget', highestTarget);
    }

    if (successCount > recordSuccesses) {
      storage.write('recordSuccesses', successCount);
    }

    if (gameAverage > recordAverage) {
      storage.write('recordAverage', gameAverage);
    }

    // Calculate new long-term average
    double newLongtermAverage =
        ((longtermAverage * numberGames) + gameAverage) / (numberGames + 1);
    storage.write('longtermAverage', newLongtermAverage);
  }

  String getCurrentRounds() {
    List<String> displayRounds = [];
    // Show completed rounds plus current round (if not finished)
    int roundsToShow =
        results.length < 13 ? results.length + 1 : results.length;
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
    // read stats from device
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int totalSuccesses = storage.read('totalSuccesses') ?? 0;
    int recordTarget = storage.read('recordTarget') ?? 50;
    int recordSuccesses = storage.read('recordSuccesses') ?? 0;
    double recordAverage = storage.read('recordAverage') ?? 0.0;
    double longtermAverage = storage.read('longtermAverage') ?? 0.0;

    return '#S: $numberGames  #C: $totalSuccesses  ♛Z: $recordTarget  ♛C: $recordSuccesses  ♛S: ${recordAverage.toStringAsFixed(1)}  ØC: ${longtermAverage.toStringAsFixed(1)}';
  }
}
