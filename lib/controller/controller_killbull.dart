import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:provider/provider.dart';

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
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);

    roundNumbers = <int>[];
    roundScores = <int>[];
    totalScores = <int>[];
    round = 1;
    totalScore = 0;
    gameEnded = false;
  }

  @override
  void initFromProvider(BuildContext context, MenuItem item) {
    Provider.of<ControllerKillBull>(context, listen: false).init(item);
  }
  @override
  void pressNumpadButton(BuildContext context, int value) {
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
        // Use post-frame callback to avoid context across async gaps
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSummaryDialog(context);
        });
      } else {
        // continue to next round
        round++;
      }
    }
    notifyListeners();
  }

  // Show summary dialog using SummaryDialog widget
  void _showSummaryDialog(BuildContext context) {
    // Update game statistics
    _updateGameStats();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(
          lines: [
            SummaryLine('Runden', '$round'),
            SummaryLine('Punkte', '$totalScore'),
            SummaryLine('Punkte/Runde', _getAvgScore().toStringAsFixed(1),
                emphasized: true),
          ],
        );
      },
    );
  }

  // Update game statistics
  void _updateGameStats() {
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int recordRounds = _storageService!.read<int>('recordRounds', defaultValue: 0)!;
    int recordScore = _storageService!.read<int>('recordScore', defaultValue: 0)!;
    double longtermScore = _storageService!.read<double>('longtermScore', defaultValue: 0.0)!;

    _storageService!.write('numberGames', numberGames + 1);
    if (recordRounds == 0 || round > recordRounds) {
      _storageService!.write('recordRounds', round);
    }
    if (recordScore == 0 || totalScore > recordScore) {
      _storageService!.write('recordScore', totalScore);
    }
    _storageService!.write('longtermScore',
        (((longtermScore * numberGames) + totalScore) / (numberGames + 1)));
  }

  double _getAvgScore() {
    return round == 1 ? 0 : (totalScore / (round - 1));
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
    return {
      'round': round,
      'totalScore': totalScore,
      'avgScore': _getAvgScore().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int recordRounds = _storageService!.read<int>('recordRounds', defaultValue: 0)!;
    int recordScore = _storageService!.read<int>('recordScore', defaultValue: 0)!;
    double longtermScore = _storageService!.read<double>('longtermScore', defaultValue: 0.0)!;
    return '#S: $numberGames  ♛R: $recordRounds  ♛P: $recordScore  ØP: ${longtermScore.toStringAsFixed(1)}';
  }
}
