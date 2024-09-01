import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/checkout.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerRTCX extends ControllerBase
    implements MenuitemController, NumpadController {
  static final ControllerRTCX _instance = ControllerRTCX._private();

  // singleton
  ControllerRTCX._private();

  factory ControllerRTCX() {
    return _instance;
  }

  late MenuItem item; // item which created the controller
  late int max; // limit of rounds per leg (-1 = unlimited)

  List<int> throws = <int>[]; // list of checked doubles per round (index - 1)
  int currentNumber = 1; // current number to throw at
  int round = 1; // round number in game
  int dart = 0; // darts played in game
  bool finished = false; // flag if round the clock was finished

  @override
  void init(MenuItem item) {
    this.item = item;
    max = item.params['max'];

    throws = <int>[];
    currentNumber = 1;
    round = 1;
    dart = 0;
    finished = false;
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (throws.isNotEmpty) {
        round--;
        dart -= 3;
        int lastThrow = throws.removeLast();
        currentNumber -= lastThrow;
      }
      // all other buttons pressed
    } else {
      // ignore numbers greater left checks
      if (currentNumber + value <= 21) {
        // return button pressed
        if (value == -1) {
          value = 0;
        }
        dart += 3;
        throws.add(value);
        currentNumber += value;

        notifyListeners();

        // check for last number reached or limit of rounds
        if (currentNumber > 20 || (max != -1 && round == max)) {
          // remaining is dfferent here, 20 means finished game,
          // so set to current number if not
          int remaining = (currentNumber < 21) ? currentNumber : 0;
          finished = currentNumber > 20 ? true : false;
          if (finished) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return Dialog(
                    // no remaining score here, so set last one
                    child: Checkout(
                      remaining: remaining,
                      controller: this,
                    ),
                  );
                }).then((value) {
              finishGame(context);
            });
          } else {
            finishGame(context);
          }
        } else {
          round++;
        }
      }
    }
    notifyListeners();
  }

  void finishGame(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          // save stats to device, use gameno as key
          GetStorage storage = GetStorage(item.id);
          int numberGames = storage.read('numberGames') ?? 0;
          int numberFinishes = storage.read('numberFinishes') ?? 0;
          int recordDarts = storage.read('recordDarts') ?? 0;
          double longtermChecks = storage.read('longtermChecks') ?? 0;
          double avgChecks = getAvgChecks();
          storage.write('numberGames', numberGames + 1);
          if (finished) {
            storage.write('numberFinishes', numberFinishes + 1);
          }
          if (recordDarts == 0 || dart < recordDarts) {
            storage.write('recordDarts', dart);
          }
          storage.write(
              'longtermChecks',
              (((longtermChecks * numberGames) + avgChecks) /
                  (numberGames + 1)));

          String checkSymbol = finished ? " ✅" : " ❌";
          return Dialog(
            child: SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.all(5),
                    child: const Text(
                      "Zusammenfassung",
                      style: TextStyle(fontSize: 50, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(5),
                    child: Text(
                      'RTC geschafft: $checkSymbol',
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
                      'Anzahl Darts: $dart',
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
                      'Darts/Checkout: ${getCurrentStats()['avgChecks']}',
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
                        style: TextStyle(fontSize: 50, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  int getCurrentNumber() {
    return currentNumber;
  }

  double getAvgChecks() {
    return currentNumber == 1 ? 0 : (dart / (currentNumber - 1));
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
    return {
      'throw': round,
      'darts': dart,
      'avgChecks': getAvgChecks().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int numberFinishes = storage.read('numberFinishes') ?? 0;
    int recordDarts = storage.read('recordDarts') ?? 0;
    double longtermChecks = storage.read('longtermChecks') ?? 0;
    return '#S: $numberGames  #G: $numberFinishes  ♛D: $recordDarts  ØC: ${longtermChecks.toStringAsFixed(1)}';
  }
}
