import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/checkout.dart';
import 'package:dart/widget/summary.dart';
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
  List<int> remainings = <int>[]; // list of remaining points after each throw
  List<int> darts = <int>[]; // list of used darts in leg
  List<int> results = <int>[]; // list of used darts per leg
  int leg = 1; // leg number
  int round = 1; // round number in leg
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
    remainings = <int>[];
    darts = <int>[];
    results = <int>[];
    leg = 1;
    round = 1;
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
      }
      input = "";
      // return button pressed
    } else if (value == -1) {
      if (input.isNotEmpty) {
        score = int.parse(input);
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
                  child: Checkout(remaining: remaining),
                );
              }).then((value) {
            results.add(dart);
            round = 1;
            remaining = xxx;
            lastTotalDarts = totalDarts;
            dart = 0;
            rounds.clear();
            scores.clear();
            remainings.clear();
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
                    int recordScore = storage.read('recordScore') ?? 0;
                    int recordDarts = storage.read('recordDarts') ?? 0;
                    int longtermScore = storage.read('longtermScore') ?? 0;
                    int longtermDarts = storage.read('longtermDarts') ?? 0;
                    int avgScore = getAvgScore();
                    int avgDarts = getAvgDarts();
                    storage.write('numberGames', numberGames + 1);
                    if (recordScore == 0 || avgScore < recordScore) {
                      storage.write('recordScore', avgScore);
                    }
                    if (recordDarts == 0 || avgDarts < recordDarts) {
                      storage.write('recordDarts', avgDarts);
                    }
                    storage.write(
                        'longtermScore',
                        (((longtermScore * numberGames) + avgScore) /
                                (numberGames + 1))
                            .round());
                    storage.write(
                        'longtermDarts',
                        (((longtermDarts * numberGames) + avgDarts) /
                                (numberGames + 1))
                            .round());

                    return const Dialog(
                      child: Summary(),
                    );
                  });
            } else {
              leg++;
            }
          });
        }
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
    return createMultilineString(rounds, '', '', 6, false);
  }

  String getCurrentScores() {
    return createMultilineString(scores, '', '', 6, false);
  }

  String getCurrentRemainings() {
    return createMultilineString(remainings, '', '', 6, false);
  }

  String getCurrentDarts() {
    return createMultilineString(darts, '', '', 6, false);
  }

  int getAvgScore() {
    return totalRounds == 0 ? 0 : ((totalScore / totalDarts) * 3).round();
  }

  int getAvgDarts() {
    return (leg > 1) ? (lastTotalDarts / (leg - 1)).round() : 0;
  }

  Map getCurrentStats() {
    return {'round': leg, 'avgScore': getAvgScore(), 'avgDarts': getAvgDarts()};
  }

  String createMultilineString(
      List list, String prefix, String postfix, int limit, bool enumarate) {
    String result = "";
    String enhancedPrefix = "";
    String enhancesPostfix = "";
    // max limit entries
    int to = list.length;
    int from = (to > limit) ? to - limit : 0;
    for (int i = from; i < list.length; i++) {
      enhancedPrefix = enumarate
          ? '$prefix ${i + 1}: '
          : (prefix.isNotEmpty ? '$prefix: ' : '');
      enhancesPostfix = postfix.isNotEmpty ? ' $postfix' : '';
      result += '$enhancedPrefix${list[i]}$enhancesPostfix\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  void correctDarts(int value) {
    dart -= value;
    totalDarts -= value;

    notifyListeners();
  }

  @override
  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(gameno.toString());
    int numberGames = storage.read('numberGames') ?? 0;
    int recordScore = storage.read('recordScore') ?? 0;
    int recordDarts = storage.read('recordDarts') ?? 0;
    int longtermScore = storage.read('longtermScore') ?? 0;
    int longtermDarts = storage.read('longtermDarts') ?? 0;
    return '#S: $numberGames  ♛P: $recordScore  ♛D: $recordDarts  ØP: $longtermScore  ØD: $longtermDarts';
  }
}
