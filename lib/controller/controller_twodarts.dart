import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
class ControllerTwoDarts extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerTwoDarts({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerTwoDarts.create() {
    return ControllerTwoDarts();
  }

  // Factory for testing with injected storage
  factory ControllerTwoDarts.forTesting(GetStorage storage) {
    return ControllerTwoDarts(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<int> targets = <int>[]; // list of targets to show
  List<bool> results = <bool>[]; // list of success/failure results
  int currentTargetIndex = 0; // current target index (0-9)
  int successCount = 0; // number of successful attempts

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    targets = <int>[61];
    results = <bool>[];
    currentTargetIndex = 0;
    successCount = 0;
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // undo button pressed
    if (value == -2) {
      if (results.isNotEmpty) {
        bool lastResult = results.removeLast();
        if (lastResult) {
          successCount--;
        }
        currentTargetIndex--;
        targets.removeLast();
      }
    } else if (value == 0 || value == 1) {
      // 0 = no (red cross), 1 = yes (green check)
      bool success = value == 1;
      results.add(success);
      if (success) {
        successCount++;
      }

      // add next target if not at the end
      if (currentTargetIndex < 9) {
        currentTargetIndex++;
        targets.add(61 + currentTargetIndex);
      }

      notifyListeners();

      // check if game is finished (all 10 targets completed)
      if (results.length == 10) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          triggerGameEnd();
        });
      }
    }
    notifyListeners();
  }


  @override
  List<SummaryLine> createSummaryLines() {
    return [
      SummaryService.createValueLine('Erfolgreiche Versuche', successCount,
          emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Two Darts';

  @override
  void updateSpecificStats() {
    // Update records
    statsService.updateRecord<int>('recordSuccesses', successCount);

    // Update long-term average
    statsService.updateLongTermAverage(
        'longtermSuccesses', successCount.toDouble());
  }

  String getCurrentTargets() {
    return createMultilineString(targets, [], '', '', [], 5, false);
  }

  String getCurrentResults() {
    // Create a list that matches the targets length but only shows results for completed targets
    List<String> displayResults = [];
    for (int i = 0; i < targets.length; i++) {
      if (i < results.length) {
        displayResults.add(results[i] ? '✅' : '❌');
      } else {
        displayResults.add(''); // Empty for current target
      }
    }
    return createMultilineString(displayResults, [], '', '', [], 5, false);
  }

  @override
  bool isButtonDisabled(int value) {
    // Undo button disabled if no results to undo
    if (value == -2) return results.isEmpty;
    // Only allow yes/no buttons when game is not finished
    if (value == 0 || value == 1) return results.length >= 10;
    return true; // all other buttons disabled
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  String getInput() {
    if (currentTargetIndex < 10) {
      return 'Ziel: ${61 + currentTargetIndex}';
    }
    return 'Fertig!';
  }

  Map getCurrentStats() {
    return {
      'target': currentTargetIndex < 10 ? 61 + currentTargetIndex : 70,
      'checks': successCount,
      'avgChecks':
          results.isEmpty ? 0.0 : (successCount / results.length * 100),
    };
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordSuccesses =
        statsService.getStat<int>('recordSuccesses', defaultValue: 0)!;
    double longtermSuccesses =
        statsService.getStat<double>('longtermSuccesses', defaultValue: 0.0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'C': recordSuccesses, // Checks
      },
      averages: {
        'C': longtermSuccesses, // Checks
      },
    );
  }
}
