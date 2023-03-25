import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerCatchXX extends ChangeNotifier
    implements MenuitemController, NumpadController {
  static final ControllerCatchXX _instance = ControllerCatchXX._private();

  // singleton
  ControllerCatchXX._private();

  factory ControllerCatchXX() {
    return _instance;
  }

  late int gameno; // number of game in Menu map, used also for stat reference

  List<int> targets = <int>[]; // list of targets to check
  List<int> thrownPoints = <int>[]; // list of thrown points per round
  List<int> totalPoints = <int>[]; // list of points in rounds summed up
  int points = 0; // total points
  int round = 1; // round number in game
  int target = 61; // current finish target

  @override
  void init(gameno, Map params) {
    this.gameno = gameno;

    targets = <int>[61];
    thrownPoints = <int>[];
    totalPoints = <int>[];
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
              GetStorage storage = GetStorage(gameno.toString());
              int numberGames = storage.read('numberGames') ?? 0;
              int recordPoints = storage.read('recordPoints') ?? 0;
              double longtermPoints = storage.read('longtermPoints') ?? 0;
              double avgPoints = getAvgPoints();
              storage.write('numberGames', numberGames + 1);
              if (recordPoints == 0 || points > recordPoints) {
                storage.write('recordPoints', points);
              }
              storage.write(
                  'longtermPoints',
                  (((longtermPoints * numberGames) + avgPoints) /
                      (numberGames + 1)));

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
                          'Anzahl Punkte: $points',
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
                          'Punkte/Runde: ${getCurrentStats()['avgPoints']}',
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
      } else {
        round++;
        target++;
      }
    }
    notifyListeners();
  }

  String createMultilineString(List list1, List list2, String prefix,
      String postfix, List optional, int limit, bool enumarate) {
    String result = "";
    String enhancedPrefix = "";
    String enhancesPostfix = "";
    String optionalStatus = "";
    String listText = "";
    // max limit entries
    int to = list1.length;
    int from = (to > limit) ? to - limit : 0;
    for (int i = from; i < list1.length; i++) {
      enhancedPrefix = enumarate
          ? '$prefix ${i + 1}: '
          : (prefix.isNotEmpty ? '$prefix: ' : '');
      enhancesPostfix = postfix.isNotEmpty ? ' $postfix' : '';
      if (optional.isNotEmpty) {
        optionalStatus = optional[i] ? " ✅" : " ❌";
      }
      listText = list2.isEmpty ? '${list1[i]}' : '${list1[i]}: ${list2[i]}';
      result += '$enhancedPrefix$listText$enhancesPostfix$optionalStatus\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  double getAvgPoints() {
    return round == 1 ? 0 : (points / (round - 1));
  }

  String getCurrentTargets() {
    return createMultilineString(targets, [], '', '', [], 6, false);
  }

  String getCurrentThrownPoints() {
    // roll 1 line earlier as targets in 1 longer, except last round
    return createMultilineString(
        thrownPoints, [], '', '', [], thrownPoints.length == 40 ? 6 : 5, false);
  }

  String getCurrentTotalPoints() {
    // roll 1 line earlier as targets in 1 longer, except last round
    return createMultilineString(
        totalPoints, [], '', '', [], totalPoints.length == 40 ? 6 : 5, false);
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
      'points': points,
      'avgPoints': getAvgPoints().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(gameno.toString());
    int numberGames = storage.read('numberGames') ?? 0;
    int recordPoints = storage.read('recordPoints') ?? 0;
    double longtermPoints = storage.read('longtermPoints') ?? 0;
    return '#S: $numberGames  ♛B: ${recordPoints.toStringAsFixed(1)}  ØH: ${longtermPoints.toStringAsFixed(1)}';
  }
}
