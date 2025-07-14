import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerKillBull extends ControllerBase
    implements MenuitemController, NumpadController {
  static final ControllerKillBull _instance = ControllerKillBull._private();

  // singleton
  ControllerKillBull._private();

  factory ControllerKillBull() {
    return _instance;
  }

  late MenuItem item; // item which created the controller

  List<int> roundNumbers = <int>[]; // list of round numbers
  List<int> roundScores = <int>[]; // list of scores per round
  List<int> totalScores = <int>[]; // list of cumulative scores
  int round = 1; // current round number
  int totalScore = 0; // total score accumulated
  bool gameEnded = false; // flag to track if game has ended

  @override
  void init(MenuItem item) {
    this.item = item;

    roundNumbers = <int>[];
    roundScores = <int>[];
    totalScores = <int>[];
    round = 1;
    totalScore = 0;
    gameEnded = false;
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (roundScores.isNotEmpty && !gameEnded) {
        round--;
        roundNumbers.removeLast();
        int lastRoundScore = roundScores.removeLast();
        totalScore -= lastRoundScore;
        totalScores.removeLast();
      }
    } else {
      // return button pressed means 0 bulls
      if (value == -1) {
        value = 0;
      }
      
      // calculate score: number of bulls * 25 points each
      int roundScore = value * 25;
      
      // add round data
      roundNumbers.add(round);
      roundScores.add(roundScore);
      totalScore += roundScore;
      totalScores.add(totalScore);
      
      notifyListeners();
      
      // check if game should end (0 bulls hit)
      if (value == 0) {
        gameEnded = true;
        showDialog(
            context: context,
            builder: (context) {
              // save stats to device
              GetStorage storage = GetStorage(item.id);
              int numberGames = storage.read('numberGames') ?? 0;
              int recordRounds = storage.read('recordRounds') ?? 0;
              int recordScore = storage.read('recordScore') ?? 0;
              double longtermScore = storage.read('longtermScore') ?? 0;
              
              storage.write('numberGames', numberGames + 1);
              if (recordRounds == 0 || round > recordRounds) {
                storage.write('recordRounds', round);
              }
              if (recordScore == 0 || totalScore > recordScore) {
                storage.write('recordScore', totalScore);
              }
              storage.write(
                  'longtermScore',
                  (((longtermScore * numberGames) + totalScore) /
                      (numberGames + 1)));

              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2))),
                child: SizedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: const Text(
                          "Zusammenfassung",
                          style: endSummaryHeaderTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'Runden: ${round - 1}',
                          style: endSummaryTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'Punkte: $totalScore',
                          style: endSummaryTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'Punkte/Runde: ${getAvgScore()}',
                          style: endSummaryEmphasizedTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: okButtonStyle,
                          child: const Text(
                            'OK',
                            style: okButtonTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
      } else {
        // continue to next round
        round++;
      }
    }
    notifyListeners();
  }

  double getAvgScore() {
    return round == 1 ? 0 : (totalScore / (round - 1));
  }

  String getCurrentRoundNumbers() {
    return createMultilineString(roundNumbers, [], '', '', [], 5, false);
  }

  String getCurrentRoundScores() {
    return createMultilineString(roundScores, [], '', '', [], 5, false);
  }

  String getCurrentTotalScores() {
    return createMultilineString(totalScores, [], '', '', [], 5, false);
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in kill bull
  }

  @override
  String getInput() {
    // not used here
    return "";
  }

  Map getCurrentStats() {
    return {
      'round': round,
      'totalScore': totalScore,
      'avgScore': getAvgScore().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordRounds = storage.read('recordRounds') ?? 0;
    int recordScore = storage.read('recordScore') ?? 0;
    double longtermScore = storage.read('longtermScore') ?? 0;
    return '#S: $numberGames  ♛R: $recordRounds  ♛P: $recordScore  ØP: ${longtermScore.toStringAsFixed(1)}';
  }
}
