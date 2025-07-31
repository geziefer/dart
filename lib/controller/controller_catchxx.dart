import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
class ControllerCatchXX extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
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
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

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
  void initFromProvider(MenuItem item) {
    init(item);
  }
  @override
  void pressNumpadButton(int value) {
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
          triggerGameEnd();
        });
      } else {
        round++;
        target++;
      }
    }
    notifyListeners();
  }


  @override
  List<SummaryLine> createSummaryLines() {
    return [
      SummaryService.createValueLine('Anzahl Checks', hits),
      SummaryService.createValueLine('Anzahl Punkte', points),
      SummaryService.createValueLine('Punkte/Runde', getCurrentStats()['avgPoints'], emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'CatchXX';

  @override
  void updateSpecificStats() {
    double avgPoints = _getAvgPoints();
    
    // Update records using StatsService
    statsService.updateRecord<int>('recordHits', hits);
    statsService.updateRecord<int>('recordPoints', points);
    
    // Update long-term average
    statsService.updateLongTermAverage('longtermPoints', avgPoints);
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

  @override
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
      'avgPoints': _getAvgPoints().toStringAsFixed(1),
    };
  }

  String getStats() {
    int numberGames = statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordHits = statsService.getStat<int>('recordHits', defaultValue: 0)!;
    int recordPoints = statsService.getStat<int>('recordPoints', defaultValue: 0)!;
    double longtermPoints = statsService.getStat<double>('longtermPoints', defaultValue: 0.0)!;
    
    return formatStatsString(
      numberGames: numberGames,
      records: {
        'C': recordHits,     // Checks
        'P': recordPoints,   // Punkte
      },
      averages: {
        'P': longtermPoints, // Durchschnittspunkte
      },
    );
  }
}
