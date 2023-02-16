import 'package:dart/view/numpad.dart';
import 'package:flutter/material.dart';

class Controller170 implements NumpadController {
  static final Controller170 _instance = Controller170._private();

  Controller170._private();

  factory Controller170() {
    return _instance;
  }

  @override
  pressNumpadButton(int value) {
    debugPrint("$value pressed");
  }

  String getCurrentRounds() {
    return '\n1\n2\n3';
  }

  String getCurrentScores() {
    return '\n100\n30\n40';
  }

  String getCurrentRemainings() {
    return '170\n70\n40\n0';
  }

  String getCurrentDarts() {
    return '\n3\n6\n8';
  }

  Map getCurrentStats() {
    return {'round': 10, 'avgScore': 70, 'avgDarts': 7};
  }
}
