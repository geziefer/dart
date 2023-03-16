import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerHalfit extends ChangeNotifier
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

  late int gameno; // number of game in Menu map, used also for stat reference

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
  void init(gameno, Map params) {
    this.gameno = gameno;

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
      round++;
      input = "";
      score = 0;

      // check for end of game
      if (round > 9) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              // save stats to device, use gameno as key
              GetStorage storage = GetStorage(gameno.toString());
              int numberGames = storage.read('numberGames') ?? 0;
              int recordScore = storage.read('recordScore') ?? 0;
              int longtermScore = storage.read('longtermScore') ?? 0;
              int avgScore = getAvgScore();
              storage.write('numberGames', numberGames + 1);
              if (recordScore == 0 || totalScore > recordScore) {
                storage.write('recordScore', totalScore);
              }
              storage.write(
                  'longtermScore',
                  (((longtermScore * numberGames) + avgScore) /
                          (numberGames + 1))
                      .round());

              return Dialog(
                child: SizedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: const Text(
                          "Zusammenfassung",
                          style: TextStyle(fontSize: 50, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Text(
                          'Punkte: $totalScore',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(5, 5, 50, 5),
                        child: Text(
                          createMultilineString(
                              labels, scores, '', '', hit, 10, false),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Text(
                          'ØPunkte: ${getCurrentStats()['avgScore']}',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(150, 80),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(fontSize: 50, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
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
    return createMultilineString(rounds, [], '', '', [], 6, false);
  }

  String getCurrentScores() {
    return createMultilineString(scores, [], '', '', [], 6, false);
  }

  String getCurrentTotals() {
    return createMultilineString(totals, [], '', '', [], 6, false);
  }

  int getAvgScore() {
    return round == 1 ? 0 : ((totalScore - 40) / (round - 1)).round();
  }

  Map getCurrentStats() {
    return {'round': round, 'avgScore': getAvgScore()};
  }

  String createMultilineString(List list1, List list2, String prefix,
      String postfix, List optional, int limit, bool enumarate) {
    String result = "";
    String enhancedPrefix = "";
    String enhancesPostfix = "";
    String optionalStatus = "";
    String listText = "";
    // max limit entries
    int to = list1.length;
    int from = (to > limit) ? to - limit : 0;
    for (int i = from; i < list1.length; i++) {
      enhancedPrefix = enumarate
          ? '$prefix ${i + 1}: '
          : (prefix.isNotEmpty ? '$prefix: ' : '');
      enhancesPostfix = postfix.isNotEmpty ? ' $postfix' : '';
      if (optional.isNotEmpty) {
        optionalStatus = optional[i] ? " ✅" : " ❌";
      }
      listText = list2.isEmpty ? '${list1[i]}' : '${list1[i]}: ${list2[i]}';
      result += '$enhancedPrefix$listText$enhancesPostfix$optionalStatus\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(gameno.toString());
    int numberGames = storage.read('numberGames') ?? 0;
    int recordScore = storage.read('recordScore') ?? 0;
    int longtermScore = storage.read('longtermScore') ?? 0;
    return '#S: $numberGames  ♛P: $recordScore  ØP: $longtermScore';
  }
}
