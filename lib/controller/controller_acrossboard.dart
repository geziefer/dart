import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ControllerAcrossBoard extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerAcrossBoard({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerAcrossBoard.create() {
    return ControllerAcrossBoard();
  }

  // Factory for testing with injected storage
  factory ControllerAcrossBoard.forTesting(GetStorage storage) {
    return ControllerAcrossBoard(storage: storage);
  }

  MenuItem? item;
  int max = -1; // not used in this game

  // Opposite number pairs on dartboard
  static const Map<int, int> oppositeNumbers = {
    20: 3, 3: 20,
    19: 2, 2: 19,
    18: 7, 7: 18,
    17: 6, 6: 17,
    16: 8, 8: 16,
    15: 10, 10: 15,
    14: 9, 9: 14,
    13: 11, 11: 13,
    12: 5, 5: 12,
    1: 4, 4: 1,
  };

  // Target types
  static const List<String> targetTypes = ['D', 'BS', 'T', 'SS', 'SB', 'DB', 'SB', 'SS', 'T', 'BS', 'D'];

  int startNumber = 1; // randomly selected start number
  int oppositeNumber = 1; // opposite of start number
  List<String> targetSequence = []; // complete sequence of targets
  List<bool> targetsHit = []; // which targets have been hit
  int currentTargetIndex = 0; // current target to hit
  int round = 1;
  int dart = 0;
  bool finished = false;

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    // Generate random start number and create target sequence
    _initializeGame();
    notifyListeners();
  }

  List<int> roundHits = []; // track hits per round for proper undo

  void _initializeGame() {
    // Select random start number (1-20)
    startNumber = Random().nextInt(20) + 1;
    oppositeNumber = oppositeNumbers[startNumber]!;
    
    // Create target sequence
    targetSequence = [
      'D$startNumber',
      'BS$startNumber', 
      'T$startNumber',
      'SS$startNumber',
      'SB',
      'DB', 
      'SB',
      'SS$oppositeNumber',
      'T$oppositeNumber',
      'BS$oppositeNumber',
      'D$oppositeNumber'
    ];
    
    // Initialize hit tracking
    targetsHit = List.filled(11, false);
    roundHits = [];
    currentTargetIndex = 0;
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
    if (finished) return;

    if (value == -2) { // Undo
      if (roundHits.isNotEmpty) {
        // Get the last round's hits
        int lastRoundHits = roundHits.removeLast();
        
        // Revert the targets hit in that round
        for (int i = 0; i < lastRoundHits; i++) {
          if (currentTargetIndex > 0) {
            currentTargetIndex--;
            targetsHit[currentTargetIndex] = false;
          }
        }
        
        // Revert round and dart counters
        round--;
        dart -= 3;
      }
      notifyListeners();
      return;
    }

    if (value == -1) { // Enter (0 hits)
      value = 0;
    }

    if (value >= 0 && value <= 3) {
      // Calculate remaining targets
      int remainingTargets = 11 - currentTargetIndex;
      
      // Limit hits to remaining targets
      int actualHits = value > remainingTargets ? remainingTargets : value;
      
      // Store this round's hits for undo functionality
      roundHits.add(actualHits);
      
      // Mark targets as hit
      for (int i = 0; i < actualHits; i++) {
        if (currentTargetIndex < 11) {
          targetsHit[currentTargetIndex] = true;
          currentTargetIndex++;
        }
      }
      
      dart += 3;
      round++;
      
      // Check if game is finished
      if (currentTargetIndex >= 11) {
        finished = true;
        notifyListeners();
        
        // Show checkout dialog for last round darts
        onShowCheckout?.call(actualHits, 0);
      } else {
        notifyListeners();
      }
    }
  }

  void handleCheckoutClosed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      triggerGameEnd();
    });
  }

  @override
  List<SummaryLine> createSummaryLines() {
    return [
      SummaryService.createValueLine('Anzahl Darts', dart),
      SummaryService.createValueLine('Darts/Target', _getAvgDartsPerTarget().toStringAsFixed(1), emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Across Board';

  @override
  void updateSpecificStats() {
    double avgDartsPerTarget = _getAvgDartsPerTarget();

    if (finished) {
      int numberFinishes = statsService.getStat<int>('numberFinishes', defaultValue: 0)!;
      statsService.updateStats({'numberFinishes': numberFinishes + 1});
      
      int recordDarts = statsService.getStat<int>('recordDarts', defaultValue: 0)!;
      if (recordDarts == 0 || dart < recordDarts) {
        statsService.updateStats({'recordDarts': dart});
      }
    }

    statsService.updateLongTermAverage('longtermChecks', avgDartsPerTarget);
  }

  double _getAvgDartsPerTarget() {
    return currentTargetIndex == 0 ? 0 : (dart / currentTargetIndex);
  }

  @override
  String getInput() {
    return "";
  }

  @override
  void correctDarts(int value) {
    dart -= value;
    notifyListeners();
  }

  @override
  bool isButtonDisabled(int value) {
    if (finished) return true;
    
    if (value > 0) {
      int remainingTargets = 11 - currentTargetIndex;
      return value > remainingTargets;
    }
    return false;
  }

  Map getCurrentStats() {
    return {
      'throw': round,
      'darts': dart,
      'avgChecks': _getAvgDartsPerTarget().toStringAsFixed(1),
    };
  }

  String getStats() {
    int numberGames = statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int numberFinishes = statsService.getStat<int>('numberFinishes', defaultValue: 0)!;
    int recordDarts = statsService.getStat<int>('recordDarts', defaultValue: 0)!;
    double longtermChecks = statsService.getStat<double>('longtermChecks', defaultValue: 0.0)!;

    return '#S: $numberGames  ♛D: $recordDarts  #G: $numberFinishes  ØT: ${longtermChecks.toStringAsFixed(1)}';
  }

  // Getters for the view
  List<String> getTargetSequence() => targetSequence;
  List<bool> getTargetsHit() => targetsHit;
  int getCurrentTargetIndex() => currentTargetIndex;
  int getStartNumber() => startNumber;
  int getOppositeNumber() => oppositeNumber;
}
