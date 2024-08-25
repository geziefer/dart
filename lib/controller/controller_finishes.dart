import 'dart:math';

import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';

class ControllerFinishes extends ChangeNotifier implements MenuitemController {
  static final ControllerFinishes _instance = ControllerFinishes._private();

  // singleton
  ControllerFinishes._private();

  factory ControllerFinishes() {
    return _instance;
  }

  static final Map<int, List<String>> finishes = {
    170: ["T20; T20; DB", "-"],
    167: ["T20; T19; DB", "-"],
    164: ["T19; T19; DB", "-"],
    161: ["T20; T17; DB", "-"],
    160: ["T20; T20; D20", "-"],
    158: ["T20; T20; D19", "-"],
    157: ["T20; T19; D20", "-"],
    156: ["T20; T20; D18", "-"],
    155: ["T20; T19; D19", "-"],
    154: ["T19; T19; D20", "-"],
    153: ["T20; T19; D18", "-"],
    152: ["T20; T20; D16", "-"],
    151: ["T20; T17; D20", "-"],
    150: ["T19; T19; D18", "-"],
    149: ["T20; T19; D16", "-"],
    148: ["T18; T18; D20", "-"],
    147: ["T20; T17; D18", "-"],
    146: ["T19; T19; D16", "-"],
    145: ["T20; T15; D20", "-"],
    144: ["T20; T20; D12", "-"],
    143: ["T20; T17; D16", "-"],
    142: ["T17; T17; D20", "-"],
    141: ["T20; T19; D12", "-"],
    140: ["T18; T18; D16", "-"],
    139: ["T19; T14; D20", "-"],
    138: ["T19; T19; D12", "-"],
    137: ["T20; T15; D16", "-"],
    136: ["T20; T20; D8", "-"],
    135: ["DB; T15; D20", "SB; T20; DB"],
    134: ["T20; T14; D16", ""],
    133: ["T20; T19; D8", ""],
    132: ["DB; T14; D20", "SB; T19; DB"],
    131: ["T20; T13; D16", ""],
    130: ["T20; T20; D5", "S20; T20; DB"],
    129: ["T19; T16; D12", "S19; T20; DB"],
    128: ["T18; T18; D10", "S18; T20; DB"],
    127: ["T20; T17; D8", "S20; T19; DB"],
    126: ["T19; T19; D6", "S19; T19; DB"],
    125: ["DB; T17; D12", "SB; T20; D20"],
    124: ["T20; T16; D8", "S20; T18; DB"],
    123: ["T19; T16; D9", "S19; T18; DB"],
    122: ["T18; T18; D7", "S18; T18; DB"],
    121: ["T20; T11; D14", "S20; T17; DB"],
    120: ["T20; S20; D20", "S20; T20; D20"],
    119: ["T19; T12; D13", "S19; T20; D20"],
    118: ["T20; S18; D20", "S20; T20; D19"],
    117: ["T20; S17; D20", "S20; T19; D20"],
    116: ["T20; S16; D20", "S20; T20; D18"],
    115: ["T20; S15; D20", "S20; T19; D19"],
    114: ["T20; S14; D20", "S20; T18; D20"],
    113: ["T19; S16; D20", "S19; T18; D20"],
    112: ["T20; S12; D20", "S20; T20; D16"],
    111: ["T20; S11; D20", "S20; T17; D20"],
    110: ["T20; S10; D20", "S20; T18; D18"],
    109: ["T19; S20; D16", "S19; T18; D18"],
    108: ["T20; S16; D16", "S20; T20; D14"],
    107: ["T19; S18; D16", "S19; T20; D19"],
    106: ["T20; S14; D16", "S20; T18; D16"],
    105: ["T20; S13; D16", "S20; T18; D16"],
    104: ["T19; S15; D16", "S19; T15; D20"],
    103: ["T19; S14; D16", "S19; T20; D12"],
    102: ["T20; S10; D16", "S20; T14; D20"],
    101: ["T20; S9; D16", "S20; T17; D15"],
    100: ["T20; D20;-", "S20; D20; D20"],
    99: ["T19; S10; D16", "S19; D20; D20"],
    98: ["T20; D19;-", "S20; T18; D12"],
    97: ["T19; D20;-", "S19; T18; D12"],
    96: ["T20; D18;-", "S20; T20; D8"],
    95: ["T19; D19;-", "S19; T20; D8"],
    94: ["T18; D20;-", "S18; T20; D8"],
    93: ["T19; D18;-", "S19; T14; D16"],
    92: ["T20; D16;-", "S20; T16; D12"],
    91: ["T17; D20;-", "S17; T14; D16"],
    90: ["T20; D15;-", "S20; S20; DB"],
    89: ["T19; D16;-", "S19; S20; DB"],
    88: ["T20; D14;-", "S20; T20; D4"],
    87: ["T17; D18;-", "S17; S20; DB"],
    86: ["T18; D16;-", "S18; T20; D4"],
    85: ["T15; D20;-", "S15; S20; DB"],
    84: ["T20; D12;-", "S20; S14; DB"],
    83: ["T17; D16;-", "S17; S16; DB"],
    82: ["DB; D16;-", "SB; S17; D20"],
    81: ["T15; D18;-", "S15; S16; DB"],
    80: ["T20; D10;-", "S20; S20; D20"],
    79: ["T19; D11;-", "S19; S20; D20"],
    78: ["T18; D12;-", "S18; S20; D20"],
    77: ["T19; D10;-", "S19; S18; D20"],
    76: ["T20; D8;-", "S20; S16; D20"],
    75: ["T17; D12;-", "S17; S18; D20"],
    74: ["T14; D16;-", "S14; S20; D20"],
    73: ["T19; D8;-", "S19; S14; D20"],
    72: ["T16; D12;-", "S16; S16; D20"],
    71: ["T13; D16;-", "S13; S18; D20"],
    70: ["T18; D8;-", "S18; S20; D16"],
    69: ["T15; D12;-", "S15; S14; D20"],
    68: ["T20; D4;-", "S20; S16; D16"],
    67: ["T17; D8;-", "S17; S18; D16"],
    66: ["T10; D18;-", "S10; S16; D20"],
    65: ["SB; D20;-", "DB; S7; D4"],
    64: ["T16; D8;-", "S16; S16; D16"],
    63: ["T13; D12;-", "S13; S18; D16"],
    62: ["T10; D16;-", "S10; S20; D16"],
    61: ["T15; D8;-", "S15; S14; D16"],
  };

  late MenuItem item; // item which created the controller
  late int from;
  late int to;
  int currentFinish = 0;
  String currentSolution = "";
  bool question = true;

  @override
  void init(MenuItem item) {
    this.item = item;
    from = item.params['from'];
    to = item.params['to'];
    createRandomFinish();
  }

  void createRandomFinish() {
    var r = Random();
    int finish = r.nextInt(to - from + 1) + from;
    currentFinish = finish;
    currentSolution = finishes[currentFinish]!.join("\n");
  }

  String getQuestionText() {
    return "Finish ${currentFinish.toString()}:";
  }

  String getSolutionText() {
    return question ? "\n" : currentSolution.toString();
  }

  void toggle() {
    question = !question;
    if (question) {
      createRandomFinish();
    }
    notifyListeners();
  }
}
