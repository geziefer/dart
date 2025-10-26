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
  String selectedMode = ''; // Selected mode: 'RTCD' or 'RTCT'
  bool _dialogShown = false; // Flag to prevent multiple dialog displays

  bool isChallengeMode = false; // if true, running in challenge mode
  Function(int)? onGameCompleted; // callback to report score to parent controller
  String? challengeStepInfo; // challenge step info for display

  List<int> throws = <int>[]; // list of checked doubles per round (index - 1)
  int currentNumber = 1; // current number to throw at
  int round = 1; // round number in game
  int dart = 0; // darts played in game
  bool finished = false; // flag if round the clock was finished

  @override
  void init(MenuItem item) {
    this.item = item;
    max = item.params['max'];

    // Check if mode selection is needed
    if (item.params['needsModeSelection'] == true) {
      selectedMode = ''; // Reset mode selection
      _dialogShown = false; // Reset dialog flag
      // Don't initialize storage service yet - wait for mode selection
    } else {
      selectedMode = item.id; // Use the item ID as mode
      _dialogShown = true; // No dialog needed
      _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
      initializeServices(_storageService!);
    }

    throws = <int>[];
    currentNumber = 1;
    round = 1;
    dart = 0;
    finished = false;
  }

  void setMode(String mode, int maxValue) {
    selectedMode = mode;
    max = maxValue;
    _dialogShown = true;
    
    // Update storage service with the selected mode
    _storageService = StorageService(mode, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);
    
    notifyListeners();
  }

  void markDialogShown() {
    _dialogShown = true;
  }

  bool get needsModeSelection => selectedMode.isEmpty && !_dialogShown;

  String get gameTitle {
    switch (selectedMode) {
      case 'RTCD':
        return 'Round the Clock Double';
      case 'RTCT':
        return 'Round the Clock Triple';
      default:
        return 'Round the Clock';
    }
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

        // Advance by the input value (number of targets hit)
        int advancement = value;

        // Check if this input will complete the game or hit round limit
        bool willCompleteGame = (currentNumber + advancement > 20);
        bool willHitRoundLimit = (max != -1 && round == max);

        if (willCompleteGame || willHitRoundLimit) {
          // Update game state first
          dart += 3;
          throws.add(advancement);
          currentNumber += advancement;
          finished = currentNumber > 20 ? true : false;

          notifyListeners();

          // Handle challenge mode differently
          if (isChallengeMode) {
            // Challenge mode: skip checkout dialog, count 2 darts for last round
            dart -= 1; // Correct from 3 to 2 darts
            triggerGameEnd();
          } else if (finished) {
            // Normal mode: only show checkout dialog if game was actually completed
            // Calculate how many targets were actually hit in this final input
            int targetsHit = advancement;
            
            // Show checkout dialog - pass the number of targets hit as remaining parameter
            // This ensures the checkout dialog shows the correct dart options
            onShowCheckout?.call(targetsHit, 0);
          } else {
            // Game not completed but hit round limit - go straight to game end
            triggerGameEnd();
          }
        } else {
          // Normal round - just update state
          dart += 3;
          throws.add(advancement);
          currentNumber += advancement;
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
  void showSummaryDialog(BuildContext context) {
    if (isChallengeMode) {
      // In Challenge mode, don't show the default summary dialog
      // The Challenge controller will handle advancement
      return;
    }
    // Normal mode - show the default summary dialog
    super.showSummaryDialog(context);
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
    // Don't update stats if services not initialized yet
    if (_storageService == null) {
      return;
    }

    if (isChallengeMode) {
      // Report score to parent controller if callback is set
      // In Challenge mode, always call the callback when game ends (finished or not)
      if (onGameCompleted != null) {
        int hits = currentNumber > 20 ? 20 : currentNumber - 1;
        onGameCompleted!(hits);
      }
      return;
    }

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
    // Disable buttons that would make currentNumber + value > 21
    // This happens when there are only 1 or 2 targets remaining
    if (value > 0) {
      // Don't disable return button (-1) or undo button (-2)
      return currentNumber + value > 21;
    }
    return false; // Return button and undo button are never disabled
  }

  Map getCurrentStats() {
    return {
      'throw': round,
      'darts': dart,
      'avgChecks': _getAvgChecks().toStringAsFixed(1),
    };
  }

  String getStats() {
    // Return empty stats if services not initialized yet (waiting for mode selection)
    if (_storageService == null) {
      return 'Wähle Spielmodus...';
    }

    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int numberFinishes =
        statsService.getStat<int>('numberFinishes', defaultValue: 0)!;
    int recordDarts =
        statsService.getStat<int>('recordDarts', defaultValue: 0)!;
    double longtermChecks =
        statsService.getStat<double>('longtermChecks', defaultValue: 0.0)!;

    if (isChallengeMode) {
      return challengeStepInfo ?? "Challenge Mode";
    } else {
      return '#S: $numberGames  ♛D: $recordDarts  #G: $numberFinishes  ØC: ${longtermChecks.toStringAsFixed(1)}';
    }
  }
}
