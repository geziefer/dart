import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:provider/provider.dart';

class ControllerDoublePath extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerDoublePath({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerDoublePath.create() {
    return ControllerDoublePath();
  }

  // Factory for testing with injected storage
  factory ControllerDoublePath.forTesting(GetStorage storage) {
    return ControllerDoublePath(storage: storage);
  }

  MenuItem? item; // item which created the controller

  List<String> targets = <String>[]; // list of target sequences
  List<int> hitCounts = <int>[]; // number of targets hit per round (0-3)
  List<int> points = <int>[]; // points scored per round
  List<int> totalPoints = <int>[]; // cumulative total points
  int currentRound = 0; // current round (0-4)

  // Fixed target sequences for the 5 rounds
  static const List<String> targetSequences = [
    '16-8-4',
    '20-10-5',
    '4-2-1',
    '12-6-3',
    '18-9-B'
  ];

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    targets = List.from(targetSequences);
    hitCounts = <int>[];
    points = <int>[];
    totalPoints = <int>[];
    currentRound = 0;
    notifyListeners();
  }

  @override
  void initFromProvider(BuildContext context, MenuItem item) {
    Provider.of<ControllerDoublePath>(context, listen: false).init(item);
  }
  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (hitCounts.isNotEmpty) {
        hitCounts.removeLast();
        points.removeLast();
        totalPoints.removeLast();
        currentRound--;
        notifyListeners();
      }
      return;
    }

    // handle hit count input (0, 1, 2, 3) or enter (treated as 0)
    int hits = 0;
    if (value >= 0 && value <= 3) {
      hits = value;
    } else if (value == -1) {
      // enter key
      hits = 0;
    } else {
      return; // ignore other values
    }

    // calculate points based on hits
    int roundPoints = _calculatePoints(hits);

    hitCounts.add(hits);
    points.add(roundPoints);

    // calculate total points
    int total = points.fold(0, (sum, p) => sum + p);
    totalPoints.add(total);

    currentRound++;
    notifyListeners();

    // check if game is finished (all 5 rounds completed)
    if (currentRound >= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSummaryDialog(context);
      });
    }
  }

  int _calculatePoints(int hits) {
    switch (hits) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 6;
      default:
        return 0;
    }
  }

  void _showSummaryDialog(BuildContext context) {
    // save stats to device
    _updateGameStats();

    int totalScore = totalPoints.isNotEmpty ? totalPoints.last : 0;
    double averagePerRound = totalScore / 5.0;

    List<SummaryLine> summaryLines = [
      SummaryLine('Punkte', '$totalScore', emphasized: true),
      SummaryLine('Punkte pro Runde', averagePerRound.toStringAsFixed(1)),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(lines: summaryLines);
      },
    );
  }

  void _updateGameStats() {
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int totalGamePoints = _storageService!.read<int>('totalPoints', defaultValue: 0)!;
    int recordRoundPoints = _storageService!.read<int>('recordRoundPoints', defaultValue: 0)!;
    double recordRoundAverage = _storageService!.read<double>('recordRoundAverage', defaultValue: 0.0)!;
    double longtermAverage = _storageService!.read<double>('longtermAverage', defaultValue: 0.0)!;

    int gameTotal = totalPoints.isNotEmpty ? totalPoints.last : 0;
    double gameAverage = gameTotal / 5.0;
    int maxRoundPoints =
        points.isNotEmpty ? points.reduce((a, b) => a > b ? a : b) : 0;

    _storageService!.write('numberGames', numberGames + 1);
    _storageService!.write('totalPoints', totalGamePoints + gameTotal);

    if (maxRoundPoints > recordRoundPoints) {
      _storageService!.write('recordRoundPoints', maxRoundPoints);
    }

    if (gameAverage > recordRoundAverage) {
      _storageService!.write('recordRoundAverage', gameAverage);
    }

    // Calculate new long-term average
    double newLongtermAverage =
        ((longtermAverage * numberGames) + gameAverage) / (numberGames + 1);
    _storageService!.write('longtermAverage', newLongtermAverage);
  }

  String getCurrentTargets() {
    List<String> displayTargets = [];
    // Show completed rounds plus current round (if not finished)
    int roundsToShow = currentRound < 5 ? currentRound + 1 : currentRound;
    for (int i = 0; i < roundsToShow; i++) {
      displayTargets.add(targetSequences[i]);
    }
    return createMultilineString(displayTargets, [], '', '', [], 5, false);
  }

  String getCurrentPoints() {
    List<String> displayPoints = [];
    // Show points for completed rounds only
    for (int i = 0; i < currentRound; i++) {
      displayPoints.add('${points[i]}');
    }
    // Add empty string for current round if game not finished
    if (currentRound < 5) {
      displayPoints.add('');
    }
    return createMultilineString(displayPoints, [], '', '', [], 5, false);
  }

  String getCurrentTotalPoints() {
    List<String> displayTotals = [];
    // Show total points for completed rounds only
    for (int i = 0; i < currentRound; i++) {
      displayTotals.add('${totalPoints[i]}');
    }
    // Add empty string for current round if game not finished
    if (currentRound < 5) {
      displayTotals.add('');
    }
    return createMultilineString(displayTotals, [], '', '', [], 5, false);
  }

  @override
  bool isButtonDisabled(int value) {
    // Game finished, disable all input
    if (currentRound >= 5) return true;

    // Undo button disabled if no rounds completed
    if (value == -2) return hitCounts.isEmpty;

    // Allow 0, 1, 2, 3 and enter (-1)
    if (value >= 0 && value <= 3) return false;
    if (value == -1) return false; // enter key

    return true; // all other buttons disabled
  }

  @override
  void correctDarts(int value) {
    // not used here
  }

  @override
  String getInput() {
    return ''; // Keep input section empty for this game
  }

  Map getCurrentStats() {
    int currentTotal = totalPoints.isNotEmpty ? totalPoints.last : 0;
    double currentAverage =
        currentRound > 0 ? currentTotal / currentRound : 0.0;

    return {
      'round': currentRound,
      'totalPoints': currentTotal,
      'averagePerRound': currentAverage,
    };
  }

  String getStats() {
    // read stats from device
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int recordRoundPoints = _storageService!.read<int>('recordRoundPoints', defaultValue: 0)!;
    double recordRoundAverage = _storageService!.read<double>('recordRoundAverage', defaultValue: 0.0)!;
    double longtermAverage = _storageService!.read<double>('longtermAverage', defaultValue: 0.0)!;

    return '#S: $numberGames  ♛P: $recordRoundPoints  ♛Ø: ${recordRoundAverage.toStringAsFixed(1)}  ØP: ${longtermAverage.toStringAsFixed(1)}';
  }
}
