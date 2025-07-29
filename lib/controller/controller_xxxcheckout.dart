import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/checkout.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerXXXCheckout extends ControllerBase
    implements MenuitemController, NumpadController {
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerXXXCheckout({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerXXXCheckout.create() {
    return ControllerXXXCheckout();
  }

  // Factory for testing with injected storage
  factory ControllerXXXCheckout.forTesting(GetStorage storage) {
    return ControllerXXXCheckout(storage: storage);
  }

  MenuItem? item; // item which created the controller

  int xxx = 0; // score to start with
  int max = 0; // limit of rounds per leg (-1 = unlimited)
  int end = 0; // number of rounds after game ends

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
  int remaining = 0; // current remaining points in leg, will be set in init
  int dart = 0; // current used darts in leg
  int totalDarts = 0; // total number of darts used in all legs
  int lastTotalDarts = 0; // total darts after last end of leg for average
  int totalScore = 0; // total score in all legs
  int totalRounds = 0; // total rounds played in all legs
  int avgScore = 0; // average of score in all legs
  int avgDarts = 0; // average number of darts used in all legs
  String input = ""; // current input from numbpad

  @override
  void init(MenuItem item) {
    this.item = item;
    xxx = item.params['xxx'];
    max = item.params['max'];
    end = item.params['end'];

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
      // return button or pre defined value pressed or long press return
    } else if (value == -3 || value == -1 || value > 9) {
      // convert pre-defined results before continueing with enter
      if (value > 9) {
        String newInput = input + value.toString();
        int parsedNewInput = int.tryParse(newInput) ?? 181;
        if (parsedNewInput <= 180 &&
            parsedNewInput <= remaining &&
            remaining - parsedNewInput != 1) {
          input = newInput;
        } else {
          return;
        }
      }

      // convert input to remaining in case of long pressed enter,
      // this includes finishing
      if (value == -3) {
        int parsedInput = int.tryParse(input) ?? 0;
        if (parsedInput != 1 && remaining - parsedInput <= 180) {
          input = (remaining - parsedInput).toString();
        } else {
          return;
        }
      }

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
        // Use a callback-based approach to avoid context across async gaps
        _showCheckoutDialog(context);
        return; // Return early to prevent further processing
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

  // Show checkout dialog using a callback-based approach
  void _showCheckoutDialog(BuildContext context) {
    // Use a synchronous method to show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2))),
          child: Checkout(
            remaining: remaining,
            controller: this,
          ),
        );
      },
    ).then((_) {
      // Process results after dialog is closed
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

      // Check if we need to show the summary dialog
      if (leg == end) {
        // Update game stats
        _updateGameStats();

        // Use a separate method to show the summary dialog
        // This avoids using the original context across async gaps
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSummaryDialog(context);
        });
      }

      leg++;
    });
  }

  // Helper method to create individual summary lines with separate symbols
  List<SummaryLine> _createSummaryLines() {
    List<SummaryLine> lines = [];
    
    // Add individual lines for each leg result with check symbols
    for (int i = 0; i < results.length && i < finishes.length; i++) {
      String checkSymbol = finishes[i] ? "✅" : "❌";
      lines.add(SummaryLine('Leg ${i + 1}', '${results[i]} Darts', checkSymbol: checkSymbol));
    }
    
    // Add average score line
    lines.add(SummaryLine('ØPunkte', getCurrentStats()['avgScore'], emphasized: true));
    
    // Add average darts line
    lines.add(SummaryLine('ØDarts', getCurrentStats()['avgDarts'], emphasized: true));
    
    return lines;
  }

  // Show summary dialog
  void _showSummaryDialog(BuildContext context) {
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

  // This method is no longer needed as the logic is now in _showCheckoutDialog

  // Update game statistics
  void _updateGameStats() {
    GetStorage storage = _injectedStorage ?? GetStorage(item?.id ?? 'xxxcheckout');
    int numberGames = storage.read('numberGames') ?? 0;
    int recordFinishes = storage.read('recordFinishes') ?? 0;
    double recordScore = storage.read('recordScore') ?? 0;
    double recordDarts = storage.read('recordDarts') ?? 0;
    double longtermScore = storage.read('longtermScore') ?? 0;
    double longtermDarts = storage.read('longtermDarts') ?? 0;
    double avgScore = _getAvgScore();
    double avgDarts = _getAvgDarts();

    // Update storage
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
    storage.write('longtermScore',
        (((longtermScore * numberGames) + avgScore) / (numberGames + 1)));
    storage.write('longtermDarts',
        (((longtermDarts * numberGames) + avgDarts) / (numberGames + 1)));
  }

  @override
  String getInput() {
    return input;
  }

  String getCurrentRounds() {
    return createMultilineString(rounds, [], '', '', [], 5, false);
  }

  String getCurrentScores() {
    return createMultilineString(scores, [], '', '', [], 5, false);
  }

  String getCurrentRemainings() {
    return createMultilineString(remainings, [], '', '', [], 5, false);
  }

  String getCurrentDarts() {
    return createMultilineString(darts, [], '', '', [], 5, false);
  }

  double _getAvgScore() {
    return totalRounds == 0 ? 0 : ((totalScore / totalDarts) * 3);
  }

  double _getAvgDarts() {
    return leg == 1 ? 0 : (lastTotalDarts / (leg - 1));
  }

  Map getCurrentStats() {
    return {
      'round': leg,
      'avgScore': _getAvgScore().toStringAsFixed(1),
      'avgDarts': _getAvgDarts().toStringAsFixed(1)
    };
  }

  @override
  void correctDarts(int value) {
    dart -= value;
    totalDarts -= value;

    notifyListeners();
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in xxxcheckout
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = _injectedStorage ?? GetStorage(item?.id ?? 'xxxcheckout');
    int numberGames = storage.read('numberGames') ?? 0;
    int recordFinishes = storage.read('recordFinishes') ?? 0;
    double recordScore = storage.read('recordScore') ?? 0;
    double recordDarts = storage.read('recordDarts') ?? 0;
    double longtermScore = storage.read('longtermScore') ?? 0;
    double longtermDarts = storage.read('longtermDarts') ?? 0;
    return '#S: $numberGames  ♛G: $recordFinishes  ♛P: ${recordScore.toStringAsFixed(1)}  ♛D: ${recordDarts.toStringAsFixed(1)}  ØP: ${longtermScore.toStringAsFixed(1)}  ØD: ${longtermDarts.toStringAsFixed(1)}';
  }
}
