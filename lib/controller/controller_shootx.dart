import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class ControllerShootx extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerShootx({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerShootx.create() {
    return ControllerShootx();
  }

  // Factory for testing with injected storage
  factory ControllerShootx.forTesting(GetStorage storage) {
    return ControllerShootx(storage: storage);
  }

  MenuItem? item; // item which created the controller

  bool skipLongtermStorage = false; // if true, don't update longterm stats
  Function(int)? onGameCompleted; // callback to report score to parent controller
  String? challengeStepInfo; // challenge step info for display

  int x = 0; // number to throw at
  int max = 0; // limit of rounds per leg

  List<int> rounds = <int>[]; // list of round numbers (index - 1)
  List<int> thrownNumbers = <int>[]; // list of thrown number per round
  List<int> totalNumbers = <int>[]; // list of number in rounds summed up
  int number = 0; // thrown number
  int round = 1; // round number in game

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);
    x = item.params['x'];
    max = item.params['max'];

    rounds = <int>[];
    thrownNumbers = <int>[];
    totalNumbers = <int>[];
    number = 0;
    round = 1;
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // undo button pressed
    if (value == -2) {
      if (rounds.isNotEmpty) {
        round--;

        int lastHits = thrownNumbers.removeLast();
        number -= lastHits;
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
        // Use post-frame callback to avoid context across async gaps
        WidgetsBinding.instance.addPostFrameCallback((_) {
          triggerGameEnd();
        });
      } else {
        round++;
      }
    }
    notifyListeners();
  }

  // Show summary dialog using SummaryDialog widget

  @override
  void showSummaryDialog(BuildContext context) {
    if (skipLongtermStorage) {
      // In Challenge mode, don't show the default summary dialog
      // The Challenge controller will handle advancement
      return;
    }
    // Normal mode - show the default summary dialog
    super.showSummaryDialog(context);
  }

  @override
  List<SummaryLine> createSummaryLines() {
    return [
      SummaryService.createValueLine('Anzahl $x', number),
      SummaryService.createValueLine('$x/Runde', getCurrentStats()['avgHits'],
          emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'ShootX';

  @override
  void updateSpecificStats() {
    if (skipLongtermStorage) {
      // Report score to parent controller if callback is set
      if (onGameCompleted != null) {
        onGameCompleted!(number); // total points scored
      }
      return;
    }

    double avgHits = double.parse(getCurrentStats()['avgHits']);

    // Update records
    statsService.updateRecord<int>('recordNumbers', number);

    // Update long-term average
    statsService.updateLongTermAverage('longtermHits', avgHits);
  }

  double _getAvgNumbers() {
    return rounds.isEmpty ? 0 : (number / rounds.length);
  }

  String getCurrentRounds() {
    return createMultilineString(rounds, [], '', '', [], 5, false);
  }

  String getCurrentThrownNumbers() {
    return createMultilineString(thrownNumbers, [], '', '', [], 5, false);
  }

  String getCurrentTotalNumbers() {
    return createMultilineString(totalNumbers, [], '', '', [], 5, false);
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in shootx
  }

  @override
  String getInput() {
    // not used here
    return "";
  }

  Map getCurrentStats() {
    return {
      'round': round,
      'hits': number,
      'avgHits': _getAvgNumbers().toStringAsFixed(1),
    };
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordNumbers =
        statsService.getStat<int>('recordNumbers', defaultValue: 0)!;
    double longtermNumbers =
        statsService.getStat<double>('longtermHits', defaultValue: 0.0)!;

    if (skipLongtermStorage) {
      return challengeStepInfo ?? "Challenge Mode";
    } else {
      return '#S: $numberGames  ♛T: $recordNumbers  ØT: ${longtermNumbers.toStringAsFixed(1)}';
    }
  }
}
