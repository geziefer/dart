import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

class ControllerHalfit extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerHalfit({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerHalfit.create() {
    return ControllerHalfit();
  }

  // Factory for testing with injected storage
  factory ControllerHalfit.forTesting(GetStorage storage) {
    return ControllerHalfit(storage: storage);
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

  MenuItem? item; // item which created the controller

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
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);

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
  void initFromProvider(BuildContext context, MenuItem item) {
    Provider.of<ControllerHalfit>(context, listen: false).init(item);
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
        // Use post-frame callback to avoid context across async gaps
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSummaryDialog(context);
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

  // Helper method to create individual summary lines with separate symbols
  List<SummaryLine> _createSummaryLines() {
    List<SummaryLine> lines = [];
    
    // Add the total score line
    lines.add(SummaryLine('Punkte', '$totalScore'));
    
    // Add individual lines for each label/score with check symbols
    for (int i = 0; i < labels.length && i < scores.length; i++) {
      String checkSymbol = hit[i] ? "✅" : "❌";
      lines.add(SummaryLine(labels[i], '${scores[i]}', checkSymbol: checkSymbol));
    }
    
    // Add average score line
    lines.add(SummaryLine('ØPunkte', getCurrentStats()['avgScore'], emphasized: true));
    
    return lines;
  }

  // Show summary dialog using SummaryDialog widget
  void _showSummaryDialog(BuildContext context) {
    // Update game statistics
    _updateGameStats();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(
          lines: _createSummaryLines(),
        );
      },
    );
  }

  // Update game statistics
  void _updateGameStats() {
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int recordScore = _storageService!.read<int>('recordScore', defaultValue: 0)!;
    double longtermScore = _storageService!.read<double>('longtermScore', defaultValue: 0.0)!;
    double avgScore = _getAvgScore();

    _storageService!.write('numberGames', numberGames + 1);
    if (recordScore == 0 || totalScore > recordScore) {
      _storageService!.write('recordScore', totalScore);
    }
    _storageService!.write('longtermScore',
        (((longtermScore * numberGames) + avgScore) / (numberGames + 1)));
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

  double _getAvgScore() {
    return round == 1 ? 0 : ((totalScore - 40) / (round - 1));
  }

  Map getCurrentStats() {
    return {'round': round, 'avgScore': _getAvgScore().toStringAsFixed(1)};
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
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int recordScore = _storageService!.read<int>('recordScore', defaultValue: 0)!;
    double longtermScore = _storageService!.read<double>('longtermScore', defaultValue: 0.0)!;
    return '#S: $numberGames  ♛P: $recordScore  ØP: ${longtermScore.toStringAsFixed(1)}';
  }
}
