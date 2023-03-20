import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerBulls extends ChangeNotifier
    implements MenuitemController, NumpadController {
  static final ControllerBulls _instance = ControllerBulls._private();

  // singleton
  ControllerBulls._private();

  factory ControllerBulls() {
    return _instance;
  }

  late int gameno; // number of game in Menu map, used also for stat reference

  List<int> rounds = <int>[]; // list of round numbers (index - 1)
  List<int> thrownBulls = <int>[]; // list of thrown bulls per round
  List<int> totalBulls = <int>[]; // list of bulls in rounds summed up
  int bulls = 0; // thrown bulls
  int round = 1; // round number in game

  @override
  void init(gameno, Map params) {
    this.gameno = gameno;

    rounds = <int>[];
    thrownBulls = <int>[];
    totalBulls = <int>[];
    bulls = 0;
    round = 1;
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (rounds.isNotEmpty) {
        round--;

        int lastBulls = thrownBulls.removeLast();
        bulls -= lastBulls;
        rounds.removeLast();
        totalBulls.removeLast();
      }
      // all other buttons pressed
    } else {
      // return button pressed
      if (value == -1) {
        value = 0;
      }
      rounds.add(round);
      round++;
      thrownBulls.add(value);
      bulls += value;
      totalBulls.add(bulls);

      // check for limit of rounds
      if (round > 10) {
        showDialog(
            context: context,
            builder: (context) {
              // save stats to device, use gameno as key
              GetStorage storage = GetStorage(gameno.toString());
              int numberGames = storage.read('numberGames') ?? 0;
              int recordBulls = storage.read('recordBulls') ?? 0;
              int longtermBulls = storage.read('longtermBulls') ?? 0;
              int avgBulls = getAvgBulls();
              storage.write('numberGames', numberGames + 1);
              if (recordBulls == 0 || bulls < recordBulls) {
                storage.write('recordBulls', bulls);
              }
              storage.write(
                  'longtermBulls',
                  (((longtermBulls * numberGames) + avgBulls) /
                          (numberGames + 1))
                      .round());

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
                          'Anzahl Bulls: $bulls',
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
                          'Bulls/Round: ${getCurrentStats()['avgBulls']}',
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

  int getAvgBulls() {
    return round == 1 ? 0 : (bulls / (round - 1)).round();
  }

  String getCurrentRounds() {
    return createMultilineString(rounds, [], '', '', [], 6, false);
  }

  String getCurrentThrownBulls() {
    return createMultilineString(thrownBulls, [], '', '', [], 6, false);
  }

  String getCurrentTotalBulls() {
    return createMultilineString(totalBulls, [], '', '', [], 6, false);
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
      'round': round,
      'bulls': bulls,
      'avgBulls': getAvgBulls(),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(gameno.toString());
    int numberGames = storage.read('numberGames') ?? 0;
    int recordBulls = storage.read('recordBulls') ?? 0;
    int longtermBulls = storage.read('longtermBulls') ?? 0;
    return '#S: $numberGames  ♛B: $recordBulls  ØH: $longtermBulls';
  }
}
