import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:flutter/material.dart';

class ControllerRTCX extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerRTCX({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerRTCX.create() {
    return ControllerRTCX();
  }

  // Factory for testing with injected storage
  factory ControllerRTCX.forTesting(GetStorage storage) {
    return ControllerRTCX(storage: storage);
  }

  MenuItem? item; // item which created the controller
  int max = -1; // limit of rounds per leg (-1 = unlimited)

  List<int> throws = <int>[]; // list of checked doubles per round (index - 1)
  int currentNumber = 1; // current number to throw at
  int round = 1; // round number in game
  int dart = 0; // darts played in game
  bool finished = false; // flag if round the clock was finished

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);
    max = item.params['max'];

    throws = <int>[];
    currentNumber = 1;
    round = 1;
    dart = 0;
    finished = false;
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
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

        // Check if this input will complete the game or hit round limit
        bool willCompleteGame = (currentNumber + value > 20);
        bool willHitRoundLimit = (max != -1 && round == max);

        if (willCompleteGame || willHitRoundLimit) {
          // Calculate remaining targets BEFORE updating currentNumber
          int remainingTargets =
              currentNumber > 20 ? 0 : (20 - currentNumber + 1);

          // Update game state
          dart += 3;
          throws.add(value);
          currentNumber += value;
          finished = currentNumber > 20 ? true : false;

          notifyListeners();

          // Show checkout dialog before ending the game
          onShowCheckout?.call(
              remainingTargets, 0); // score parameter not used in target mode
        } else {
          // Normal round - just update state
          dart += 3;
          throws.add(value);
          currentNumber += value;
          round++;

          notifyListeners();
        }
      }
    }
    notifyListeners();
  }

  // Checkout and summary dialogs are now handled by the view via callbacks

  /// Handle checkout dialog being closed - trigger game end
  void handleCheckoutClosed() {
    // Use post frame callback to ensure dialog is fully closed before showing summary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      triggerGameEnd();
    });
  }

  @override
  List<SummaryLine> createSummaryLines() {
    String checkSymbol = finished ? "✅" : "❌";
    return [
      SummaryLine('RTC geschafft', '', checkSymbol: checkSymbol),
      SummaryService.createValueLine('Anzahl Darts', dart),
      SummaryService.createValueLine(
          'Darts/Checkout', getCurrentStats()['avgChecks'],
          emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'RTCX';

  @override
  void updateSpecificStats() {
    double avgChecks = double.parse(getCurrentStats()['avgChecks']);

    // Update finish count if game was completed
    if (finished) {
      int numberFinishes =
          statsService.getStat<int>('numberFinishes', defaultValue: 0)!;
      statsService.updateStats({'numberFinishes': numberFinishes + 1});
    }

    // Update records (lower dart count is better for finished games)
    if (finished) {
      int recordDarts =
          statsService.getStat<int>('recordDarts', defaultValue: 0)!;
      if (recordDarts == 0 || dart < recordDarts) {
        statsService.updateStats({'recordDarts': dart});
      }
    }

    // Update long-term average
    statsService.updateLongTermAverage('longtermChecks', avgChecks);
  }

  int getCurrentNumber() {
    return currentNumber;
  }

  double _getAvgChecks() {
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

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in rtcx
  }

  Map getCurrentStats() {
    return {
      'throw': round,
      'darts': dart,
      'avgChecks': _getAvgChecks().toStringAsFixed(1),
    };
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int numberFinishes =
        statsService.getStat<int>('numberFinishes', defaultValue: 0)!;
    int recordDarts =
        statsService.getStat<int>('recordDarts', defaultValue: 0)!;
    double longtermChecks =
        statsService.getStat<double>('longtermChecks', defaultValue: 0.0)!;

    String baseStats = formatStatsString(
      numberGames: numberGames,
      records: {
        'D': recordDarts, // Darts
      },
      averages: {
        'C': longtermChecks, // Checks
      },
    );
    return '$baseStats  #G: $numberFinishes'; // Add finishes count separately
  }
}
