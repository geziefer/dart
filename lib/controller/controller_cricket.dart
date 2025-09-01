import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:flutter/material.dart';

class ControllerCricket extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerCricket({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerCricket.create() {
    return ControllerCricket();
  }

  // Factory for testing with injected storage
  factory ControllerCricket.forTesting(GetStorage storage) {
    return ControllerCricket(storage: storage);
  }

  MenuItem? item; // item which created the controller

  // Cricket game state
  Map<int, int> hits = {}; // number -> hit count (0-3)
  int round = 1;
  int totalHits = 0;
  List<List<int>> roundHits = [[]]; // 2D array: roundHits[round-1] = list of hits in that round

  // Getter for hits map
  Map<int, int> get getHits => hits;
  
  // Getter for round
  int get getRound => round;
  
  // Get current round hits for display
  List<int> get currentRoundHits => roundHits[round - 1];

  String input = ""; // current input from numbpad

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    // Initialize cricket numbers (15-20, Bull=25)
    hits = {15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0, 25: 0};
    round = 1;
    totalHits = 0;
    roundHits = [[]]; // Start with one empty round
    input = "";
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // Prevent operation before initialization
    if (item == null) return;

    // undo button pressed
    if (value == -2) {
      _undoLastHit();
    } else if (value == -1 || value == 0) {
      // enter button or 0 pressed - end round
      round++;
      roundHits.add([]); // Add new empty round
      _updateInput();
    } else if (value == 15 || value == 16 || value == 17 || value == 18 || value == 19 || value == 20 || value == 25) {
      // cricket number pressed - check if input is valid
      if (_canAddHit(value)) {
        hits[value] = hits[value]! + 1;
        totalHits++;
        roundHits[round - 1].add(value);
        _updateInput();
        
        // Check if game is complete
        if (hits.values.every((count) => count >= 3)) {
          // Game completed - trigger end
          WidgetsBinding.instance.addPostFrameCallback((_) {
            triggerGameEnd();
          });
        }
      }
    }

    notifyListeners();
  }

  void _undoLastHit() {
    // Check if current round has hits
    if (roundHits[round - 1].isNotEmpty) {
      // Remove last hit from current round
      int lastHit = roundHits[round - 1].removeLast();
      hits[lastHit] = hits[lastHit]! - 1;
      totalHits--;
    } else if (round > 1) {
      // Current round is empty, go back to previous round
      roundHits.removeLast(); // Remove empty current round
      round--;
      // Now undo the last hit from the previous round (if any)
      if (roundHits[round - 1].isNotEmpty) {
        int lastHit = roundHits[round - 1].removeLast();
        hits[lastHit] = hits[lastHit]! - 1;
        totalHits--;
      }
    }
    
    _updateInput();
  }

  bool _canAddHit(int value) {
    // Can't hit if number is already closed
    if (hits[value]! >= 3) return false;
    
    // Get distinct numbers already hit in current round
    Set<int> distinctNumbers = currentRoundHits.toSet();
    
    // Count bulls in current round
    int bullsInRound = currentRoundHits.where((hit) => hit == 25).length;
    
    // Special bull constraint: if we want to score 3rd bull, we can only have 1 other distinct number
    if (value == 25 && bullsInRound == 2) {
      // Trying to add 3rd bull - check if we already have more than 1 other distinct number
      Set<int> otherNumbers = distinctNumbers.where((num) => num != 25).toSet();
      if (otherNumbers.length > 1) return false;
    }
    
    // If adding 3rd bull and we already have 1 other number, that's the limit
    if (value == 25 && bullsInRound == 2 && distinctNumbers.length > 1) {
      return true; // This is allowed (3 bulls + 1 other number)
    }
    
    // If we already have 3 bulls, we can only add the same other number that's already there
    if (bullsInRound >= 3 && value != 25) {
      Set<int> otherNumbers = distinctNumbers.where((num) => num != 25).toSet();
      if (otherNumbers.length > 0 && !otherNumbers.contains(value)) return false;
    }
    
    // Standard constraint: max 3 distinct numbers
    if (!distinctNumbers.contains(value) && distinctNumbers.length >= 3) {
      return false;
    }
    
    return true;
  }

  void _updateInput() {
    List<int> currentHits = roundHits[round - 1];
    if (currentHits.isEmpty) {
      input = "";
    } else {
      input = currentHits.map((hit) => hit == 25 ? 'B' : hit.toString()).join('-');
    }
  }

  @override
  List<SummaryLine> createSummaryLines() {
    List<SummaryLine> lines = [];
    lines.add(SummaryLine('Game', 'Cricket'));
    return lines;
  }

  @override
  String getGameTitle() => 'Cricket';

  @override
  void updateSpecificStats() {
    // TODO: Implement cricket-specific stats
  }

  @override
  String getInput() {
    return input;
  }

  @override
  void correctDarts(int value) {
    // TODO: Implement dart correction for cricket
    notifyListeners();
  }

  @override
  bool isButtonDisabled(int value) {
    return value == -99; // disable buttons with value -99 (former 7 and 9 in cricket mode)
  }

  String getCricketBoard() {
    final numbers = [15, 16, 17, 18, 19, 20, 25];
    final lines = <String>[];
    
    for (int number in numbers) {
      String numberStr = number == 25 ? 'Bull' : number.toString();
      String circles = '';
      for (int i = 0; i < 3; i++) {
        circles += i < hits[number]! ? '●' : '○';
      }
      lines.add('$numberStr $circles');
    }
    
    return lines.join('\n');
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {},
      averages: {},
    );
  }
}
