import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ControllerShootx extends ChangeNotifier
    implements MenuitemController, NumpadController {
  static final ControllerShootx _instance = ControllerShootx._private();

  // singleton
  ControllerShootx._private();

  factory ControllerShootx() {
    return _instance;
  }

  late MenuItem item; // item which created the controller

  late int x; // number to throw at
  late int max; // limit of rounds per leg

  List<int> rounds = <int>[]; // list of round numbers (index - 1)
  List<int> thrownNumbers = <int>[]; // list of thrown number per round
  List<int> totalNumbers = <int>[]; // list of number in rounds summed up
  int number = 0; // thrown number
  int round = 1; // round number in game

  @override
  void init(MenuItem item) {
    this.item = item;
    x = item.params['x'];
    max = item.params['max'];

    rounds = <int>[];
    thrownNumbers = <int>[];
    totalNumbers = <int>[];
    number = 0;
    round = 1;
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (rounds.isNotEmpty) {
        round--;

        int lastBulls = thrownNumbers.removeLast();
        number -= lastBulls;
        rounds.removeLast();
        totalNumbers.removeLast();
      }
      // all other buttons pressed
    } else {
      // return button pressed
      if (value == -1) {
        value = 0;
      }
      rounds.add(round);
      thrownNumbers.add(value);
      number += value;
      totalNumbers.add(number);

      notifyListeners();

      // check for limit of rounds
      if (round == max) {
        showDialog(
            context: context,
            builder: (context) {
              // save stats to device, use gameno as key
              GetStorage storage = GetStorage(item.id);
              int numberGames = storage.read('numberGames') ?? 0;
              int recordNumbers = storage.read('recordNumbers') ?? 0;
              double longtermNumbers = storage.read('longtermNumbers') ?? 0;
              double avgNumbers = getAvgNumbers();
              storage.write('numberGames', numberGames + 1);
              if (recordNumbers == 0 || number > recordNumbers) {
                storage.write('recordNumbers', number);
              }
              storage.write(
                  'longtermNumbers',
                  (((longtermNumbers * numberGames) + avgNumbers) /
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
                          'Anzahl $x: $number',
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
                          '$x/Runde: ${getCurrentStats()['avgBulls']}',
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

  double getAvgNumbers() {
    return round == 1 ? 0 : (number / (round - 1));
  }

  String getCurrentRounds() {
    return createMultilineString(rounds, [], '', '', [], 6, false);
  }

  String getCurrentThrownNumbers() {
    return createMultilineString(thrownNumbers, [], '', '', [], 6, false);
  }

  String getCurrentTotalNumbers() {
    return createMultilineString(totalNumbers, [], '', '', [], 6, false);
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
      'bulls': number,
      'avgBulls': getAvgNumbers().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = GetStorage(item.id);
    int numberGames = storage.read('numberGames') ?? 0;
    int recordNumbers = storage.read('recordNumbers') ?? 0;
    double longtermNumbers = storage.read('longtermNumbers') ?? 0;
    return '#S: $numberGames  ♛N: ${recordNumbers.toStringAsFixed(1)}  ØH: ${longtermNumbers.toStringAsFixed(1)}';
  }
}
