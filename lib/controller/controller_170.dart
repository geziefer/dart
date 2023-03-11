import 'package:dart/view/checkout.dart';
import 'package:dart/view/numpad.dart';
import 'package:flutter/material.dart';

class Controller170 extends ChangeNotifier implements NumpadController {
  static final Controller170 _instance = Controller170._private();

  // singleton
  Controller170._private();

  factory Controller170() {
    return _instance;
  }

  List<int> rounds = <int>[]; // list of rounds in leg
  List<int> scores = <int>[]; // list of thrown scores in leg
  List<int> remainings = <int>[]; // list of remaining points after each throw
  List<int> darts = <int>[]; // list of used darts in leg
  List<int> results = <int>[]; // list of used darts per leg
  int leg = 1; // leg number
  int round = 1; // round number in leg
  int score = 0; // current score in leg
  int remaining = 170; // current remaining points in leg
  int dart = 0; // current used darts in leg
  int totalDarts = 0; // total number of darts used in all legs
  int totalScore = 0; // total score in all legs
  int totalRounds = 0; // total rounds played in all legs
  int avgScore = 0; // average of score in all legs
  int avgDarts = 0; // average number of darts used in all legs
  String input = ""; // current input from numbpad

  void init() {
    rounds = <int>[];
    scores = <int>[];
    remainings = <int>[];
    darts = <int>[];
    results = <int>[];
    leg = 1;
    round = 1;
    score = 0;
    remaining = 170;
    dart = 0;
    totalDarts = 0;
    totalScore = 0;
    totalRounds = 0;
    avgScore = 0;
    avgDarts = 0;
    input = "";
  }

  @override
  pressNumpadButton(BuildContext context, int value) {
    // undo
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
      // return
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

        // check for checkout
        if (remaining == 0) {
          showDialog(
              context: context,
              builder: (context) {
                return const Dialog(
                  child: Checkout(),
                );
              }).then((value) {
            results.add(dart);
            round = 1;
            remaining = 170;
            dart = 0;
            rounds.clear();
            scores.clear();
            remainings.clear();
            darts.clear();

            // check for end of game
            if (leg == 10) {
              // TODO: replace by summary in view
              String result = "";
              for (int i = 0; i < results.length; i++) {
                result += '${results[i]} ';
              }
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Spiel vorbei"),
                    content: Text(result),
                    actions: <Widget>[
                      TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }),
                    ],
                  );
                },
              );
            } else {
              leg++;
            }
          });
        }
      }
      // number
    } else {
      // only accept current digit if it fits in remaining and does not use >4 digits
      String newInput = input + value.toString();
      int parsedNewInput = int.tryParse(newInput) ?? 171;
      if (parsedNewInput <= 170 &&
          parsedNewInput <= remaining &&
          newInput.length <= 3) {
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
    return createMultilineString(rounds);
  }

  String getCurrentScores() {
    return createMultilineString(scores);
  }

  String getCurrentRemainings() {
    return createMultilineString(remainings);
  }

  String getCurrentDarts() {
    return createMultilineString(darts);
  }

  Map getCurrentStats() {
    avgScore = totalRounds == 0 ? 0 : ((totalScore / totalDarts) * 3).round();
    avgDarts = (totalDarts / leg).round();
    return {'round': leg, 'avgScore': avgScore, 'avgDarts': avgDarts};
  }

  String createMultilineString(List list) {
    String result = "";
    // max 6 entries
    int to = list.length;
    int from = (to > 6) ? to - 6 : 0;
    for (int i = from; i < list.length; i++) {
      result += '${list[i]}\n';
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
}
