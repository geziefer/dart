import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

class ControllerCatchXX extends ControllerBase
    implements MenuitemController, NumpadController {
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerCatchXX({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerCatchXX.create() {
    return ControllerCatchXX();
  }

  // Factory for testing with injected storage
  factory ControllerCatchXX.forTesting(GetStorage storage) {
    return ControllerCatchXX(storage: storage);
  }

  MenuItem? item; // item which created the controller

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
  void initFromProvider(BuildContext context, MenuItem item) {
    Provider.of<ControllerCatchXX>(context, listen: false).init(item);
  }
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
      // ignore button 1 as it's not possible to finish in 1 dart
      if (value == 1) {
        return;
      }
      
      int dartsUsed = value;
      // return button pressed or 0 means no score (more than 6 darts)
      if (value == -1 || value == 0) {
        dartsUsed = 0;
      }
      
      // calculate points based on darts used
      int calculatedPoints = _calculatePoints(dartsUsed);
      
      hits += calculatedPoints > 0 ? 1 : 0;
      thrownHits.add(calculatedPoints > 0 ? 1 : 0);
      if (target < 100) {
        targets.add(target + 1);
      }
      thrownPoints.add(calculatedPoints);
      points += calculatedPoints;
      totalPoints.add(points);

      notifyListeners();

      // check for limit of rounds
      if (target == 100) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSummaryDialog(context);
        });
      } else {
        round++;
        target++;
      }
    }
    notifyListeners();
  }

  void _showSummaryDialog(BuildContext context) {
    // save stats to device, use gameno as key
    _updateGameStats();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(
          lines: [
            SummaryLine('Anzahl Checks', '$hits'),
            SummaryLine('Anzahl Punkte', '$points'),
            SummaryLine('Punkte/Runde', '${getCurrentStats()['avgPoints']}', emphasized: true),
          ],
        );
      },
    );
  }

  void _updateGameStats() {
    GetStorage storage = _injectedStorage ?? GetStorage(item?.id ?? 'catchxx');
    int numberGames = storage.read('numberGames') ?? 0;
    int recordHits = storage.read('recordHits') ?? 0;
    int recordPoints = storage.read('recordPoints') ?? 0;
    double longtermPoints = storage.read('longtermPoints') ?? 0;
    double avgPoints = _getAvgPoints();
    
    storage.write('numberGames', numberGames + 1);
    if (recordHits == 0 || hits > recordHits) {
      storage.write('recordHits', hits);
    }
    if (recordPoints == 0 || points > recordPoints) {
      storage.write('recordPoints', points);
    }
    storage.write('longtermPoints',
        (((longtermPoints * numberGames) + avgPoints) / (numberGames + 1)));
  }

  /// Calculate points based on number of darts used
  /// Special case for target 99: 3 darts = 3 points (impossible to finish in 2 darts)
  /// Normal case: 2 darts = 3 points, 3 darts = 2 points, 4-6 darts = 1 point, 0 or >6 darts = 0 points
  int _calculatePoints(int dartsUsed) {
    // Special case for target 99 - impossible to finish in 2 darts
    if (target == 99) {
      switch (dartsUsed) {
        case 3:
          return 3; // 3 points for 3 darts on target 99
        case 4:
        case 5:
        case 6:
          return 1;
        default:
          return 0; // 0 or more than 6 darts
      }
    }
    
    // Normal scoring for all other targets
    switch (dartsUsed) {
      case 2:
        return 3;
      case 3:
        return 2;
      case 4:
      case 5:
      case 6:
        return 1;
      default:
        return 0; // 0 or more than 6 darts
    }
  }

  double _getAvgPoints() {
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

  bool isButtonDisabled(int value) {
    // Button 1 is always disabled as it's not possible to finish any target in 1 dart
    if (value == 1) {
      return true;
    }
    // Button 2 is disabled for target 99 as it's impossible to finish 99 in 2 darts
    if (value == 2 && target == 99) {
      return true;
    }
    return false;
  }

  void correctDarts(int value) {
    // not used here
  }

  String getInput() {
    // not used here
    return "";
  }

  Map getCurrentStats() {
    return {
      'target': target,
      'hits': hits,
      'points': points,
      'avgPoints': _getAvgPoints().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    GetStorage storage = _injectedStorage ?? GetStorage(item?.id ?? 'catchxx');
    int numberGames = storage.read('numberGames') ?? 0;
    int recordHits = storage.read('recordHits') ?? 0;
    int recordPoints = storage.read('recordPoints') ?? 0;
    double longtermPoints = storage.read('longtermPoints') ?? 0;
    return '#S: $numberGames  ♛C: $recordHits  ♛P: $recordPoints  ØP: ${longtermPoints.toStringAsFixed(1)}';
  }
}
