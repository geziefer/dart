import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerCatchXX extends ControllerBase
    implements MenuitemController, NumpadController {
  static final ControllerCatchXX _instance = ControllerCatchXX._private();

  // singleton
  ControllerCatchXX._private();

  factory ControllerCatchXX() {
    return _instance;
  }

  late MenuItem item; // item which created the controller

  List<int> targets = <int>[]; // list of targets to check
  List<int> thrownHits = <int>[]; // list of thrown hits per round
  List<int> thrownPoints = <int>[]; // list of thrown points per round
  List<int> totalPoints = <int>[]; // list of points in rounds summed up
  int hits = 0; // number of targets hit within 6 darts
  int points = 0; // total points
  int round = 1; // round number in game
  int target = 61; // current finish target

  @override
  void init(MenuItem item) {
    this.item = item;

    targets = <int>[61];
    thrownPoints = <int>[];
    thrownHits = <int>[];
    totalPoints = <int>[];
    hits = 0;
    points = 0;
    round = 1;
    target = 61;
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (thrownPoints.isNotEmpty) {
        round--;
        target--;

        targets.removeLast();
        int lastHits = thrownHits.removeLast();
        hits -= lastHits;
        int lastPoints = thrownPoints.removeLast();
        points -= lastPoints;
        totalPoints.removeLast();
      }
      // all other buttons pressed
    } else {
      // return button pressed
      if (value == -1) {
        value = 0;
      }
      hits += value > 0 ? 1 : 0;
      thrownHits.add(1);
      if (target < 100) {
        targets.add(target + 1);
      }
      thrownPoints.add(value);
      points += value;
      totalPoints.add(points);

      notifyListeners();

      // check for limit of rounds
      if (target == 100) {
        showDialog(
            context: context,
            builder: (context) {
              // save stats to device, use gameno as key
              GetStorage storage = GetStorage(item.id);
              int numberGames = storage.read('numberGames') ?? 0;
              int recordHits = storage.read('recordHits') ?? 0;
              int recordPoints = storage.read('recordPoints') ?? 0;
              double longtermPoints = storage.read('longtermPoints') ?? 0;
              double avgPoints = getAvgPoints();
              storage.write('numberGames', numberGames + 1);
              if (recordHits == 0 || hits > recordHits) {
                storage.write('recordHits', hits);
              }
              if (recordPoints == 0 || points > recordPoints) {
                storage.write('recordPoints', points);
              }
              storage.write(
                  'longtermPoints',
                  (((longtermPoints * numberGames) + avgPoints) /
                      (numberGames + 1)));

              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2))),
                child: SizedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: const Text(
                          "Zusammenfassung",
                          style: TextStyle(fontSize: 50, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'Anzahl Checks: $hits',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'Anzahl Punkte: $points',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          'Punkte/Runde: ${getCurrentStats()['avgPoints']}',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(150, 80),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2))),
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
      } else {
        round++;
        target++;
      }
    }
    notifyListeners();
  }

  double getAvgPoints() {
    return round == 1 ? 0 : (points / (round - 1));
  }

  String getCurrentTargets() {
    return createMultilineString(targets, [], '', '', [], 5, false);
  }

  String getCurrentThrownPoints() {
    // roll 1 line earlier as targets is 1 longer, except last round
    return createMultilineString(
        thrownPoints, [], '', '', [], thrownPoints.length == 40 ? 5 : 4, false);
  }

  String getCurrentTotalPoints() {
    // roll 1 line earlier as targets is 1 longer, except last round
    return createMultilineString(
        totalPoints, [], '', '', [], totalPoints.length == 40 ? 5 : 4, false);
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  String getInput() {
    // not used here
    return "";
  }

  Map getCurrentStats() {
    return {
      'target': target,
      'hits': hits,
      'points': points,
      'avgPoints': getAvgPoints().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordHits = storage.read('recordHits') ?? 0;
    int recordPoints = storage.read('recordPoints') ?? 0;
    double longtermPoints = storage.read('longtermPoints') ?? 0;
    return '#S: $numberGames  ♛C: $recordHits  ♛P: $recordPoints  ØP: ${longtermPoints.toStringAsFixed(1)}';
  }
}
