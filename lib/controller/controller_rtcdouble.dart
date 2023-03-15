import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/checkout.dart';
import 'package:dart/widget/summary.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerRTCDouble extends ChangeNotifier
    implements MenuitemController, NumpadController {
  static final ControllerRTCDouble _instance = ControllerRTCDouble._private();

  // singleton
  ControllerRTCDouble._private();

  factory ControllerRTCDouble() {
    return _instance;
  }

  late int gameno; // number of game in Menu map, used also for stat reference
  late int max; // limit of rounds per leg (-1 = unlimited)

  List<int> throws = <int>[]; // list of checked doubles per round (index - 1)
  int currentNumber = 1; // current number to throw at
  int round = 1; // round number in game
  int dart = 0; // darts played in game

  @override
  void init(gameno, Map params) {
    this.gameno = gameno;
    max = params['max'];

    throws = <int>[];
    currentNumber = 1;
    round = 1;
    dart = 0;
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      round--;
      dart -= 3;
      int lastThrow = throws.removeLast();
      currentNumber -= lastThrow;
      // all other buttons pressed
    } else {
      // return button pressed
      if (value == -1) {
        value = 0;
      }
      round++;
      dart += 3;
      throws.add(value);
      currentNumber += value;

      // check for last number reached or limit of rounds
      if (currentNumber > 20 || (max != -1 && round > max)) {
        if (currentNumber > 20) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return Dialog(
                  // no remaining score here, so set last one
                  child: Checkout(
                    remaining: 20,
                    controller: this,
                  ),
                );
              }).then((value) {
            finishGame();
          });
        } else {
          finishGame();
        }
      }
    }
    notifyListeners();
  }

  void finishGame() {
/*
            // check for end of game
            if (leg == 00) {
              showDialog(
                  context: context,
                  builder: (context) {
                    // save stats to device, use gameno as key
                    GetStorage storage = GetStorage(gameno.toString());
                    int numberGames = storage.read('numberGames') ?? 0;
                    int recordFinishes = storage.read('recordFinishes') ?? 0;
                    int recordScore = storage.read('recordScore') ?? 0;
                    int recordDarts = storage.read('recordDarts') ?? 0;
                    int longtermScore = storage.read('longtermScore') ?? 0;
                    int longtermDarts = storage.read('longtermDarts') ?? 0;
                    int avgScore = getAvgScore();
                    int avgDarts = getAvgDarts();
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
  */
  }

  int getCurrentNumber() {
    return currentNumber;
  }

  @override
  String getInput() {
    // not used here
    return "";
  }

  @override
  void correctDarts(int value) {
    dart -= value;

    notifyListeners();
  }

  Map getCurrentStats() {
    return {}; //{'round': leg, 'avgScore': getAvgScore(), 'avgDarts': getAvgDarts()};
  }

  @override
  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(gameno.toString());
    int numberGames = storage.read('numberGames') ?? 0;
    int recordFinishes = storage.read('recordFinishes') ?? 0;
    int recordScore = storage.read('recordScore') ?? 0;
    int recordDarts = storage.read('recordDarts') ?? 0;
    int longtermScore = storage.read('longtermScore') ?? 0;
    int longtermDarts = storage.read('longtermDarts') ?? 0;
    return '#S: $numberGames ♛G: $recordFinishes  ♛P: $recordScore  ♛D: $recordDarts  ØP: $longtermScore  ØD: $longtermDarts';
  }
}
