import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerHalfit extends ControllerBase
    implements MenuitemController, NumpadController {
  static final ControllerHalfit _instance = ControllerHalfit._private();

  // singleton
  ControllerHalfit._private();

  factory ControllerHalfit() {
    return _instance;
  }

  static final labels = <String>[
    '15',
    '16',
    'D',
    '17',
    '18',
    'T',
    '19',
    '20',
    'B',
  ];

  late MenuItem item; // item which created the controller

  List<String> rounds = <String>[]; // list of rounds in game
  List<int> scores = <int>[]; // list of thrown scores in each round
  List<int> totals = <int>[]; // list of total scores in each round
  List<bool> hit = <bool>[]; // list of flags if current round's field was hit
  int round = 1; // round number in leg
  int score = 0; // current score thrown
  int totalScore = 0; // current score in game
  int avgScore = 0; // average of score in all legs
  String input = ""; // current input from numbpad

  @override
  void init(MenuItem item) {
    this.item = item;

    rounds = <String>[labels.first];
    scores = <int>[];
    totals = <int>[];
    hit = <bool>[];
    round = 1;
    score = 40;
    totalScore = 40;
    avgScore = 0;
    input = "";
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (input.isEmpty && scores.isNotEmpty) {
        rounds.removeLast();
        int lastscore = scores.removeLast();
        totals.removeLast();
        hit.removeLast();
        round--;
        totalScore -= lastscore;
        score = 0;
      }
      input = "";
      // return button pressed
    } else if (value == -1) {
      if (input.isEmpty) {
        score = 0;
      } else {
        score = int.parse(input);
      }
      // half it
      if (score == 0) {
        score = -(totalScore / 2).round();
      }
      scores.add(score);
      totalScore += score;
      totals.add(totalScore);
      if (score > 0) {
        hit.add(true);
      } else {
        hit.add(false);
      }
      if (round < 9) {
        rounds.add(labels.elementAt(round));
      }
      input = "";
      score = 0;

      notifyListeners();

      // check for end of game
      if (round == 9) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              // save stats to device, use gameno as key
              GetStorage storage = GetStorage(item.id);
              int numberGames = storage.read('numberGames') ?? 0;
              int recordScore = storage.read('recordScore') ?? 0;
              double longtermScore = storage.read('longtermScore') ?? 0;
              double avgScore = getAvgScore();
              storage.write('numberGames', numberGames + 1);
              if (recordScore == 0 || totalScore > recordScore) {
                storage.write('recordScore', totalScore);
              }
              storage.write(
                  'longtermScore',
                  (((longtermScore * numberGames) + avgScore) /
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
                          'Punkte: $totalScore',
                          style: endSummaryTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(5, 5, 50, 5),
                        child: Text(
                          createMultilineString(
                              labels, scores, '', '', hit, 10, false),
                          style: endSummaryTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'ØPunkte: ${getCurrentStats()['avgScore']}',
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
        round++;
      }
    }
    // number button pressed
    else {
      // only accept 3 digits
      String newInput = input + value.toString();
      int parsedNewInput = int.tryParse(newInput) ?? 181;
      if (parsedNewInput <= 180 && newInput.length <= 3) {
        input = newInput;
      }
    }

    notifyListeners();
  }

  @override
  String getInput() {
    return input;
  }

  String getCurrentRounds() {
    return createMultilineString(rounds, [], '', '', [], 5, false);
  }

  String getCurrentScores() {
    // roll 1 line earlier as rounds is 1 longer, except last round
    return createMultilineString(
        scores, [], '', '', [], scores.length == 9 ? 5 : 4, false);
  }

  String getCurrentTotals() {
    // roll 1 line earlier as rounds is 1 longer, except last round
    return createMultilineString(
        totals, [], '', '', [], totals.length == 9 ? 5 : 4, false);
  }

  double getAvgScore() {
    return round == 1 ? 0 : ((totalScore - 40) / (round - 1));
  }

  Map getCurrentStats() {
    return {'round': round, 'avgScore': getAvgScore().toStringAsFixed(1)};
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in halfit
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordScore = storage.read('recordScore') ?? 0;
    double longtermScore = storage.read('longtermScore') ?? 0;
    return '#S: $numberGames  ♛P: $recordScore  ØP: ${longtermScore.toStringAsFixed(1)}';
  }
}
