import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/checkout.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerXXXCheckout extends ChangeNotifier
    implements MenuitemController, NumpadController {
  static final ControllerXXXCheckout _instance =
      ControllerXXXCheckout._private();

  // singleton
  ControllerXXXCheckout._private();

  factory ControllerXXXCheckout() {
    return _instance;
  }

  late int gameno; // number of game in Menu map, used also for stat reference
  late int xxx; // score to start with
  late int max; // limit of rounds per leg (-1 = unlimited)
  late int end; // number of rounds after game ends

  List<int> rounds = <int>[]; // list of rounds in leg
  List<int> scores = <int>[]; // list of thrown scores in leg
  List<bool> finishes = <bool>[]; // list of flags if leg was finished
  List<int> remainings = <int>[]; // list of remaining points after each throw
  List<int> darts = <int>[]; // list of used darts in leg
  List<int> results = <int>[]; // list of used darts per leg
  int leg = 1; // leg number
  int round = 1; // round number in leg
  int wins = 0; // number of finished legs
  int score = 0; // current score in leg
  late int remaining; // current remaining points in leg, will be set in init
  int dart = 0; // current used darts in leg
  int totalDarts = 0; // total number of darts used in all legs
  int lastTotalDarts = 0; // total darts after last end of leg for average
  int totalScore = 0; // total score in all legs
  int totalRounds = 0; // total rounds played in all legs
  int avgScore = 0; // average of score in all legs
  int avgDarts = 0; // average number of darts used in all legs
  String input = ""; // current input from numbpad

  @override
  void init(gameno, Map params) {
    this.gameno = gameno;
    xxx = params['xxx'];
    max = params['max'];
    end = params['end'];

    rounds = <int>[];
    scores = <int>[];
    finishes = <bool>[];
    remainings = <int>[xxx];
    darts = <int>[];
    results = <int>[];
    leg = 1;
    round = 1;
    wins = 0;
    score = 0;
    remaining = xxx;
    dart = 0;
    totalDarts = 0;
    lastTotalDarts = 0;
    totalScore = 0;
    totalRounds = 0;
    avgScore = 0;
    avgDarts = 0;
    input = "";
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (input.isEmpty && rounds.isNotEmpty) {
        rounds.removeLast();
        round--;
        totalRounds--;
        dart -= 3;
        totalDarts -= 3;
        darts.removeLast();
        int lastscore = scores.removeLast();
        totalScore -= lastscore;
        remaining += lastscore;
        remainings.removeLast();
        if (remainings.isEmpty) {
          remainings.add(xxx);
        }
      }
      input = "";
      // return button pressed
    } else if (value == -1) {
      if (input.isEmpty) {
        score = 0;
      } else {
        score = int.parse(input);
      }
      if (scores.isEmpty) {
        remainings.removeLast();
      }
      rounds.add(round);
      round++;
      totalRounds++;
      dart += 3;
      totalDarts += 3;
      remaining -= score;
      darts.add(dart);
      totalScore += score;
      scores.add(score);
      remainings.add(remaining);
      input = "";
      score = 0;

      // check for checkout or limit of rounds
      if (remaining == 0 || (max != -1 && round > max)) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                child: Checkout(
                  remaining: remaining,
                  controller: this,
                ),
              );
            }).then((value) {
          results.add(dart);
          if (remaining == 0) {
            wins += 1;
            finishes.add(true);
          } else {
            finishes.add(false);
          }
          round = 1;
          remaining = xxx;
          lastTotalDarts = totalDarts;
          dart = 0;
          rounds.clear();
          scores.clear();
          remainings.clear();
          remainings.add(xxx);
          darts.clear();

          notifyListeners();

          // check for end of game
          if (leg == end) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  // save stats to device, use gameno as key
                  GetStorage storage = GetStorage(gameno.toString());
                  int numberGames = storage.read('numberGames') ?? 0;
                  int recordFinishes = storage.read('recordFinishes') ?? 0;
                  double recordScore = storage.read('recordScore') ?? 0;
                  double recordDarts = storage.read('recordDarts') ?? 0;
                  double longtermScore = storage.read('longtermScore') ?? 0;
                  double longtermDarts = storage.read('longtermDarts') ?? 0;
                  double avgScore = getAvgScore();
                  double avgDarts = getAvgDarts();
                  storage.write('numberGames', numberGames + 1);
                  if (wins == 0 || wins > recordFinishes) {
                    storage.write('recordFinishes', recordFinishes + 1);
                  }
                  if (recordScore == 0 || avgScore < recordScore) {
                    storage.write('recordScore', avgScore);
                  }
                  if (recordDarts == 0 || avgDarts < recordDarts) {
                    storage.write('recordDarts', avgDarts);
                  }
                  storage.write(
                      'longtermScore',
                      (((longtermScore * numberGames) + avgScore) /
                          (numberGames + 1)));
                  storage.write(
                      'longtermDarts',
                      (((longtermDarts * numberGames) + avgDarts) /
                          (numberGames + 1)));

                  return Dialog(
                    child: SizedBox(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(5),
                            child: const Text(
                              "Zusammenfassung",
                              style:
                                  TextStyle(fontSize: 50, color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(5),
                            child: Text(
                              createMultilineString(
                                  results, 'Leg', 'Darts', finishes, 10, true),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(5),
                            child: Text(
                              'ØPunkte: ${getCurrentStats()['avgScore']}\nØDarts: ${getCurrentStats()['avgDarts']}',
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
                                style: TextStyle(
                                    fontSize: 50, color: Colors.white),
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
            leg++;
          }
        });
      }
      // number button pressed
    } else {
      // only accept current digit if it fits in remaining and does not use >4 digits
      String newInput = input + value.toString();
      int parsedNewInput = int.tryParse(newInput) ?? 181;
      if (parsedNewInput <= 180 &&
          parsedNewInput <= remaining &&
          newInput.length <= 3 &&
          remaining - parsedNewInput != 1) {
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
    return createMultilineString(rounds, '', '', [], 6, false);
  }

  String getCurrentScores() {
    return createMultilineString(scores, '', '', [], 6, false);
  }

  String getCurrentRemainings() {
    return createMultilineString(remainings, '', '', [], 6, false);
  }

  String getCurrentDarts() {
    return createMultilineString(darts, '', '', [], 6, false);
  }

  double getAvgScore() {
    return totalRounds == 0 ? 0 : ((totalScore / totalDarts) * 3);
  }

  double getAvgDarts() {
    return leg == 1 ? 0 : (lastTotalDarts / (leg - 1));
  }

  Map getCurrentStats() {
    return {
      'round': leg,
      'avgScore': getAvgScore().toStringAsFixed(1),
      'avgDarts': getAvgDarts().toStringAsFixed(1)
    };
  }

  String createMultilineString(List list, String prefix, String postfix,
      List optional, int limit, bool enumarate) {
    String result = "";
    String enhancedPrefix = "";
    String enhancesPostfix = "";
    String optionalStatus = "";
    // max limit entries
    int to = list.length;
    int from = (to > limit) ? to - limit : 0;
    for (int i = from; i < list.length; i++) {
      enhancedPrefix = enumarate
          ? '$prefix ${i + 1}: '
          : (prefix.isNotEmpty ? '$prefix: ' : '');
      enhancesPostfix = postfix.isNotEmpty ? ' $postfix' : '';
      if (optional.isNotEmpty) {
        optionalStatus = optional[i] ? " ✅" : " ❌";
      }
      result += '$enhancedPrefix${list[i]}$enhancesPostfix$optionalStatus\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  @override
  void correctDarts(int value) {
    dart -= value;
    totalDarts -= value;

    notifyListeners();
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(gameno.toString());
    int numberGames = storage.read('numberGames') ?? 0;
    int recordFinishes = storage.read('recordFinishes') ?? 0;
    double recordScore = storage.read('recordScore') ?? 0;
    double recordDarts = storage.read('recordDarts') ?? 0;
    double longtermScore = storage.read('longtermScore') ?? 0;
    double longtermDarts = storage.read('longtermDarts') ?? 0;
    return '#S: $numberGames  ♛G: $recordFinishes  ♛P: ${recordScore.toStringAsFixed(1)}  ♛D: ${recordDarts.toStringAsFixed(1)}  ØP: ${longtermScore.toStringAsFixed(1)}  ØD: ${longtermDarts.toStringAsFixed(1)}';
  }
}
