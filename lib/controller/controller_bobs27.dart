import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerBobs27 extends ControllerBase
    implements MenuitemController, NumpadController {
  static final ControllerBobs27 _instance = ControllerBobs27._private();

  // singleton
  ControllerBobs27._private();

  factory ControllerBobs27() {
    return _instance;
  }

  late MenuItem item; // item which created the controller

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
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (roundScores.length > 1 && !gameEnded) { // need at least 2 entries (current + previous)
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
        totalScores[totalScores.length - 1] = 0; // make current total empty again
        
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
    int currentTarget = getCurrentTargetNumber();
    int roundScore = calculateScore(currentTarget, hits);
    
    // record the round (complete current row)
    roundScores[roundScores.length - 1] = roundScore; // overwrite current round score
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
    } else if (currentTargetIndex >= 20) { // completed all targets including bull
      gameEnded = true;
      gameWon = true;
    } else {
      // advance to next target (add next row with EMPTY values)
      currentTargetIndex++;
      targets.add(getCurrentTargetDisplay());
      roundScores.add(0); // add EMPTY round score (0 means empty display)
      totalScores.add(0); // add EMPTY total (0 means empty display)
      round++;
    }

    notifyListeners();

    // show summary if game ended
    if (gameEnded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSummaryDialog(context);
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

  int getCurrentTargetNumber() {
    if (currentTargetIndex < 20) {
      return currentTargetIndex + 1; // targets 1-20
    } else {
      return 21; // bull
    }
  }

  String getCurrentTargetDisplay() {
    int target = getCurrentTargetNumber();
    if (target == 21) {
      return "B";
    } else {
      return target.toString(); // just the number, no D prefix
    }
  }

  int calculateScore(int target, int hits) {
    int doubleValue;
    if (target == 21) { // bull
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
      'target': getCurrentTargetDisplay(),
      'successful': successfulRounds,
      'total': totalScore,
      'average': getAverageScore(),
    };
  }

  String getAverageScore() {
    if (round == 1) {
      return "0.0";
    }
    double avg = (totalScore - 27) / (round - 1); // exclude starting score
    return avg.toStringAsFixed(1);
  }

  String getStats() {
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordSuccessful = storage.read('recordSuccessful') ?? 0;
    int recordTotal = storage.read('recordTotal') ?? 0;
    double longtermAverage = storage.read('longtermAverage') ?? 0;
    return '#S: $numberGames  ♛E: $recordSuccessful  ♛P: $recordTotal  ØP: ${longtermAverage.toStringAsFixed(1)}';
  }

  void showSummaryDialog(BuildContext context) {
    // save stats to device
    _updateGameStats();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String checkSymbol = gameWon ? "✅" : "❌";
        return SummaryDialog(
          lines: [
            SummaryLine('Bob\'s 27 geschafft', checkSymbol),
            SummaryLine('Erfolgreiche Runden', '$successfulRounds'),
            SummaryLine('Gesamtpunkte', '$totalScore'),
            SummaryLine('Punkte/Runde', getAverageScore(), emphasized: true),
          ],
        );
      },
    );
  }

  void _updateGameStats() {
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordSuccessful = storage.read('recordSuccessful') ?? 0;
    int recordTotal = storage.read('recordTotal') ?? 0;
    double longtermAverage = storage.read('longtermAverage') ?? 0;
    double currentAverage = double.parse(getAverageScore());
    
    storage.write('numberGames', numberGames + 1);
    if (recordSuccessful == 0 || successfulRounds > recordSuccessful) {
      storage.write('recordSuccessful', successfulRounds);
    }
    if (recordTotal == 0 || totalScore > recordTotal) {
      storage.write('recordTotal', totalScore);
    }
    storage.write('longtermAverage', 
        (((longtermAverage * numberGames) + currentAverage) / (numberGames + 1)));
  }
}
