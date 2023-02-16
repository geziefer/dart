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
    return '1\n2\n3\n4\n5';
  }

  String getCurrentScores() {
    return '100\n30\n0\n20\n20';
  }

  String getCurrentRemainings() {
    return '70\n40\n40\n20\n0';
  }

  String getCurrentDarts() {
    return '3\n6\n9\n12\n13';
  }

  Map getCurrentStats() {
    return {'round': 10, 'avgScore': 70, 'avgDarts': 7};
  }
}
