import 'package:dart/view/numpad.dart';
import 'package:flutter/material.dart';

class Controller170 extends ChangeNotifier implements NumpadController {
  static final Controller170 _instance = Controller170._private();

  Controller170._private();

  factory Controller170() {
    return _instance;
  }

  List<int> rounds = <int>[];
  List<int> scores = <int>[];
  List<int> remainings = <int>[];
  List<int> darts = <int>[];
  int set = 1;
  int round = 1;
  int score = 0;
  int remaining = 170;
  int dart = 0;
  int totalDarts = 0;
  int totalScore = 0;
  int totalRounds = 0;
  int avgScore = 0;
  int avgDarts = 0;
  String input = "0";

  @override
  pressNumpadButton(int value) {
    if (value == -2) {
      if (input == "0") {
        debugPrint('zurück');
      }
      input = "0";
    } else if (value == -1) {
      rounds.add(round);
      round++;
      totalRounds++;
      dart += 3; // adapt for checkout
      totalDarts += 3;
      darts.add(dart);
      score += int.parse(input);
      totalScore += score;
      scores.add(score);
      remaining -= score;
      remainings.add(remaining);
      avgScore = (totalScore / totalRounds).round();
      avgDarts = (totalDarts / set).round();

      input = "0";
      score = 0;
      notifyListeners();
    } else {
      input += value.toString();
    }
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
    return {'round': set, 'avgScore': avgScore, 'avgDarts': avgDarts};
  }

  String createMultilineString(List list) {
    String result = "";
    for (var i in list) {
      result += '$i\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
