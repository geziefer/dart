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

  List<int> targetNumbers = <int>[]; // list of target numbers (1-20, then bull=21)
  List<int> hitsPerTarget = <int>[]; // list of hits per target (0-3)
  List<int> scoresPerTarget = <int>[]; // list of scores per target
  List<int> totalScores = <int>[]; // list of cumulative scores
  int currentTargetIndex = 0; // current target index (0-20)
  int totalScore = 27; // total score (starts with 27)
  bool gameEnded = false; // flag to track if game has ended
  bool gameWon = false; // flag to track if game was won
  int totalThrows = 0; // total number of throws made

  @override
  void init(MenuItem item) {
    this.item = item;

    targetNumbers = <int>[];
    hitsPerTarget = <int>[];
    scoresPerTarget = <int>[];
    totalScores = <int>[];
    currentTargetIndex = 0;
    totalScore = 27;
    gameEnded = false;
    gameWon = false;
    totalThrows = 0;

    // Initialize targets 1-20 plus bull (21)
    for (int i = 1; i <= 21; i++) {
      targetNumbers.add(i);
    }
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (hitsPerTarget.isNotEmpty && !gameEnded) {
        currentTargetIndex--;
        int lastHits = hitsPerTarget.removeLast();
        int lastScore = scoresPerTarget.removeLast();
        totalScore -= lastScore;
        totalScores.removeLast();
        totalThrows -= lastHits;
        notifyListeners();
      }
    }
    // return button pressed (same as 0 - no hits)
    else if (value == -1) {
      if (!gameEnded) {
        processRound(context, 0);
      }
    }
    // number buttons 0-3
    else if (value >= 0 && value <= 3) {
      if (!gameEnded) {
        processRound(context, value);
      }
    }
  }

  void processRound(BuildContext context, int hits) {
    int currentTarget = getCurrentTarget();
    int roundScore = calculateScore(currentTarget, hits);
    
    // record the round
    hitsPerTarget.add(hits);
    scoresPerTarget.add(roundScore);
    totalScore += roundScore;
    totalScores.add(totalScore);
    totalThrows += hits;

    // check game end conditions
    if (totalScore <= 0) {
      gameEnded = true;
      gameWon = false;
    } else if (currentTargetIndex >= 20) { // completed all targets including bull
      gameEnded = true;
      gameWon = true;
    } else {
      currentTargetIndex++;
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
    // not used here
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

  int getCurrentTarget() {
    if (currentTargetIndex < 20) {
      return currentTargetIndex + 1; // targets 1-20
    } else {
      return 21; // bull
    }
  }

  String getCurrentTargetDisplay() {
    int target = getCurrentTarget();
    if (target == 21) {
      return "BULL";
    } else {
      return "D$target";
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

  Map getCurrentStats() {
    return {
      'target': getCurrentTargetDisplay(),
      'score': totalScore.toString(),
      'progress': '${currentTargetIndex + 1}/21',
    };
  }

  String getStats() {
    if (totalThrows == 0) {
      return "Average: 0.0";
    }
    double average = totalScore / totalThrows;
    return "Average: ${average.toStringAsFixed(1)}";
  }

  List<SummaryLine> getSummaryLines() {
    List<SummaryLine> lines = [];
    
    for (int i = 0; i < targetNumbers.length; i++) {
      int target = targetNumbers[i];
      String displayName = target == 21 ? "BULL" : "D$target";
      
      if (i < hitsPerTarget.length) {
        int hits = hitsPerTarget[i];
        int score = scoresPerTarget[i];
        lines.add(SummaryLine(
          displayName,
          "$hits hits (${score > 0 ? '+' : ''}$score)",
        ));
      } else {
        lines.add(SummaryLine(
          displayName,
          "Not attempted",
        ));
      }
    }
    
    // Add summary statistics
    lines.add(SummaryLine('Total Score', '$totalScore', emphasized: true));
    lines.add(SummaryLine('Average', getStats().split(': ')[1]));
    
    return lines;
  }

  void showSummaryDialog(BuildContext context) {
    List<SummaryLine> lines = getSummaryLines();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SummaryDialog(
          lines: lines,
          onOk: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pop(); // go back to main menu
          },
        );
      },
    );
  }

  void saveStats() {
    if (!gameEnded) return;
    
    final storage = GetStorage();
    List<dynamic> existingStats = storage.read(item.id) ?? [];
    
    Map<String, dynamic> gameStats = {
      'date': DateTime.now().toIso8601String(),
      'won': gameWon,
      'finalScore': totalScore,
      'totalThrows': totalThrows,
      'average': totalThrows > 0 ? totalScore / totalThrows : 0.0,
      'targetsCompleted': currentTargetIndex + (gameEnded && !gameWon ? 0 : 1),
    };
    
    existingStats.add(gameStats);
    storage.write(item.id, existingStats);
  }
}
