import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:flutter/material.dart';

class ControllerKillBull extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerKillBull({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerKillBull.create() {
    return ControllerKillBull();
  }

  // Factory for testing with injected storage
  factory ControllerKillBull.forTesting(GetStorage storage) {
    return ControllerKillBull(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<int> roundNumbers = <int>[]; // list of round numbers
  List<int> roundScores = <int>[]; // list of scores per round
  List<int> totalScores = <int>[]; // list of cumulative scores
  int round = 1; // current round number
  int totalScore = 0; // total score accumulated
  bool gameEnded = false; // flag to track if game has ended

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    roundNumbers = <int>[];
    roundScores = <int>[];
    totalScores = <int>[];
    round = 1;
    totalScore = 0;
    gameEnded = false;
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
    // undo button pressed
    if (value == -2) {
      if (roundScores.isNotEmpty && !gameEnded) {
        round--;
        roundNumbers.removeLast();
        int lastRoundScore = roundScores.removeLast();
        totalScore -= lastRoundScore;
        totalScores.removeLast();
      }
    } else {
      // return button pressed means 0 bulls
      if (value == -1) {
        value = 0;
      }

      // calculate score: number of bulls * 25 points each
      int roundScore = value * 25;

      // add round data
      roundNumbers.add(round);
      roundScores.add(roundScore);
      totalScore += roundScore;
      totalScores.add(totalScore);

      notifyListeners();

      // check if game should end (0 bulls hit)
      if (value == 0) {
        gameEnded = true;
        // Trigger game end callback instead of showing dialog directly
        WidgetsBinding.instance.addPostFrameCallback((_) {
          triggerGameEnd();
        });
      } else {
        // continue to next round
        round++;
      }
    }
    notifyListeners();
  }

  // Summary dialog is now handled by the view via callback

  @override
  List<SummaryLine> createSummaryLines() {
    int roundsPlayed = roundScores.length;
    return [
      SummaryService.createValueLine('Runden', roundsPlayed),
      SummaryService.createValueLine('Punkte', totalScore),
      SummaryService.createAverageLine('Punkte/Runde', _getAvgScore(),
          emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Kill Bull';

  @override
  void updateSpecificStats() {
    int roundsPlayed = roundScores.length;
    // Update records
    statsService.updateRecord<int>('recordRounds', roundsPlayed);
    statsService.updateRecord<int>('recordScore', totalScore);

    // Update long-term average using totalScore (not avgScore) to match old behavior
    statsService.updateLongTermAverage('longtermScore', totalScore.toDouble());
  }

  double _getAvgScore() {
    // Use the actual number of rounds played (length of roundScores)
    // This is more robust than relying on the round counter
    int roundsPlayed = roundScores.length;
    return roundsPlayed == 0 ? 0 : (totalScore / roundsPlayed);
  }

  String getCurrentRoundNumbers() {
    return createMultilineString(roundNumbers, [], '', '', [], 5, false);
  }

  String getCurrentRoundScores() {
    return createMultilineString(roundScores, [], '', '', [], 5, false);
  }

  String getCurrentTotalScores() {
    return createMultilineString(totalScores, [], '', '', [], 5, false);
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in kill bull
  }

  @override
  String getInput() {
    // not used here
    return "";
  }

  Map getCurrentStats() {
    int roundsPlayed = roundScores.length;
    return {
      'round': roundsPlayed,
      'totalScore': totalScore,
      'avgScore': _getAvgScore().toStringAsFixed(1),
    };
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordRounds =
        statsService.getStat<int>('recordRounds', defaultValue: 0)!;
    int recordScore =
        statsService.getStat<int>('recordScore', defaultValue: 0)!;
    double longtermScore =
        statsService.getStat<double>('longtermScore', defaultValue: 0.0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'R': recordRounds, // Runden
        'P': recordScore, // Punkte
      },
      averages: {
        'P': longtermScore, // Durchschnittspunkte
      },
    );
  }
}
