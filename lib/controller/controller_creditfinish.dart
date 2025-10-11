import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/summary_service.dart';

enum GamePhase { scoreInput, finishInput }

class ControllerCreditFinish extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerCreditFinish({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerCreditFinish.create() {
    return ControllerCreditFinish();
  }

  // Factory for testing with injected storage
  factory ControllerCreditFinish.forTesting(GetStorage storage) {
    return ControllerCreditFinish(storage: storage);
  }

  MenuItem? item;
  int max = -1; // not used in this game

  // Game state
  GamePhase currentPhase = GamePhase.scoreInput;
  String input = "";
  List<int> scores = []; // Phase 1 scores
  List<int> credits = []; // Credits earned per round
  List<bool> finishResults =
      []; // Phase 2 results (true = success, false = miss)
  int missCount = 0;
  bool gameEnded = false;

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    // Initialize game state
    currentPhase = GamePhase.scoreInput;
    input = "";
    scores = [];
    credits = [];
    finishResults = [];
    missCount = 0;
    gameEnded = false;

    notifyListeners();
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    if (gameEnded) return;

    if (value == -2) {
      // Undo
      if (currentPhase == GamePhase.scoreInput) {
        if (input.isNotEmpty) {
          // Clear current input first
          input = "";
        } else if (scores.isNotEmpty) {
          // Undo last complete round
          scores.removeLast();
          credits.removeLast();
          bool wasSuccess = finishResults.removeLast();
          if (!wasSuccess) {
            missCount--;
          }
        }
        notifyListeners();
      }
      // Undo disabled in finish phase
      return;
    }

    if (currentPhase == GamePhase.scoreInput) {
      _handleScoreInput(value);
    } else {
      _handleFinishInput(value);
    }
  }

  void _handleScoreInput(int value) {
    if (value == -1) {
      // Return = 0
      if (input.isNotEmpty) {
        int score = int.tryParse(input) ?? 0;
        if (_isValidScore(score)) {
          _processScore(score);
        }
      } else {
        _processScore(0);
      }
    } else if (value >= 0 && value <= 9) {
      // Number input - validate during typing like xxxcheckout
      String newInput = input + value.toString();
      int parsedNewInput = int.tryParse(newInput) ?? 181;
      if (parsedNewInput <= 180 && newInput.length <= 3) {
        input = newInput;
        notifyListeners();
      }
    } else if (value > 9 && _isValidScore(value)) {
      // Predefined score buttons
      _processScore(value);
    }
  }

  bool _isValidScore(int score) {
    // Simple validation: 0-180 allowed like xxxcheckout
    return score >= 0 && score <= 180;
  }

  void _processScore(int score) {
    scores.add(score);
    int creditCount = _calculateCredits(score);
    credits.add(creditCount);

    if (creditCount == 0) {
      // Automatic miss for scores < 57
      finishResults.add(false);
      missCount++;
      _checkGameEnd();
    } else {
      // Move to finish input phase
      currentPhase = GamePhase.finishInput;
    }

    input = "";
    notifyListeners();
  }

  void _handleFinishInput(int value) {
    if (value == 0) {
      // No (❌)
      finishResults.add(false);
      missCount++;
    } else if (value == 1) {
      // Yes (✅)
      finishResults.add(true);
    }

    currentPhase = GamePhase.scoreInput;
    _checkGameEnd();
    notifyListeners();
  }

  int _calculateCredits(int score) {
    if (score < 57) return 0;
    if (score < 95) return 1;
    if (score < 133) return 2;
    return 3;
  }

  void _checkGameEnd() {
    if (missCount >= 10) {
      gameEnded = true;
      triggerGameEnd();
    }
  }

  @override
  String getInput() {
    return input;
  }

  @override
  void correctDarts(int value) {
    // Not used in this game
  }

  @override
  bool isButtonDisabled(int value) {
    if (gameEnded) return true;

    // Disable undo button in finish phase
    if (value == -2 && currentPhase == GamePhase.finishInput) {
      return true;
    }

    return false;
  }

  @override
  String getGameTitle() => 'Credit Finish';

  @override
  List<SummaryLine> createSummaryLines() {
    int totalRounds = scores.length;
    int checks = finishResults.where((result) => result).length;
    double avgChecks = totalRounds > 0 ? (checks / totalRounds) * 100 : 0;

    return [
      SummaryService.createValueLine('Gespielte Runden', totalRounds),
      SummaryService.createValueLine('Checks', checks),
      SummaryService.createValueLine(
          'ØChecks', '${avgChecks.toStringAsFixed(1)}%',
          emphasized: true),
    ];
  }

  @override
  void updateSpecificStats() {
    int totalRounds = scores.length;
    int checks = finishResults.where((result) => result).length;
    double avgChecks = totalRounds > 0 ? (checks / totalRounds) * 100 : 0;

    if (gameEnded) {
      double bestAvgChecks =
          statsService.getStat<double>('bestAvgChecks', defaultValue: 0.0)!;
      if (avgChecks > bestAvgChecks) {
        statsService.updateStats({'bestAvgChecks': avgChecks});
      }
    }

    statsService.updateLongTermAverage('longtermAvgChecks', avgChecks);
  }

  Map getCurrentStats() {
    int totalRounds = scores.length;
    int checks = finishResults.where((result) => result).length;

    return {
      'rounds': totalRounds,
      'checks': checks,
      'misses': missCount,
    };
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    double bestAvgChecks =
        statsService.getStat<double>('bestAvgChecks', defaultValue: 0.0)!;
    double longtermAvgChecks =
        statsService.getStat<double>('longtermAvgChecks', defaultValue: 0.0)!;

    return '#S: $numberGames  ♛%: ${bestAvgChecks.toStringAsFixed(1)}  Ø%: ${longtermAvgChecks.toStringAsFixed(1)}';
  }

  // Getters for the view
  GamePhase getCurrentPhase() => currentPhase;
  List<int> getScores() => scores;
  List<int> getCredits() => credits;
  List<bool> getFinishResults() => finishResults;
  int getMissCount() => missCount;

  // Methods for table display with scrolling (like xxxcheckout)
  String getCurrentRounds() {
    List<String> rounds = [];
    for (int i = 0; i < scores.length; i++) {
      rounds.add((i + 1).toString());
    }
    return createMultilineString(rounds, [], '', '', [], 5, false);
  }

  String getCurrentScores() {
    return createMultilineString(scores, [], '', '', [], 5, false);
  }

  String getCurrentCredits() {
    return createMultilineString(credits, [], '', '', [], 5, false);
  }

  String getCurrentResults() {
    List<String> results = [];
    for (int i = 0; i < finishResults.length; i++) {
      results.add(finishResults[i] ? '✅' : '❌');
    }
    return createMultilineString(results, [], '', '', [], 5, false);
  }
}
