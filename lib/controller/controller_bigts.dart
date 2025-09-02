import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:flutter/material.dart';

class ControllerBigTs extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  ControllerBigTs({GetStorage? storage}) : _injectedStorage = storage;

  factory ControllerBigTs.create() {
    return ControllerBigTs();
  }

  factory ControllerBigTs.forTesting(GetStorage storage) {
    return ControllerBigTs(storage: storage);
  }

  MenuItem? item;

  List<int> hitCounts = <int>[];
  List<int> points = <int>[];
  List<int> totalPoints = <int>[];
  int currentRound = 0;

  static const int totalRounds = 10;

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService =
        StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    hitCounts = <int>[];
    points = <int>[];
    totalPoints = <int>[];
    currentRound = 0;
    notifyListeners();
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  @override
  void pressNumpadButton(int value) {
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

    int hits = 0;
    if (value >= 0 && value <= 3) {
      hits = value;
    } else if (value == -1) {
      hits = 0;
    } else {
      return;
    }

    int roundPoints = _calculatePoints(hits);

    hitCounts.add(hits);
    points.add(roundPoints);

    int total = points.fold(0, (sum, p) => sum + p);
    totalPoints.add(total);

    currentRound++;
    notifyListeners();

    if (currentRound >= totalRounds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        triggerGameEnd();
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

  @override
  List<SummaryLine> createSummaryLines() {
    int totalScore = totalPoints.isNotEmpty ? totalPoints.last : 0;
    double averagePerRound = totalScore / totalRounds.toDouble();

    return [
      SummaryService.createValueLine('Punkte', totalScore, emphasized: true),
      SummaryService.createAverageLine('Punkte pro Runde', averagePerRound),
    ];
  }

  @override
  String getGameTitle() => 'Big Ts';

  @override
  void updateSpecificStats() {
    int gameTotal = totalPoints.isNotEmpty ? totalPoints.last : 0;
    double gameAverage = gameTotal / totalRounds.toDouble();
    int maxRoundPoints =
        points.isNotEmpty ? points.reduce((a, b) => a > b ? a : b) : 0;

    int totalGamePoints =
        statsService.getStat<int>('totalPoints', defaultValue: 0)!;
    statsService.updateStats({'totalPoints': totalGamePoints + gameTotal});

    statsService.updateRecord<int>('recordRoundPoints', maxRoundPoints);
    statsService.updateRecord<double>('recordRoundAverage', gameAverage);

    statsService.updateLongTermAverage('longtermAverage', gameAverage);
  }

  String getCurrentTargets() {
    List<String> displayRounds = [];
    for (int i = 0; i < currentRound; i++) {
      displayRounds.add('${i + 1}');
    }
    if (currentRound < totalRounds) {
      displayRounds.add('${currentRound + 1}');
    }
    return createMultilineString(displayRounds, [], '', '', [], 5, false);
  }

  String getCurrentPoints() {
    List<String> displayPoints = [];
    for (int i = 0; i < currentRound; i++) {
      displayPoints.add('${points[i]}');
    }
    if (currentRound < totalRounds) {
      displayPoints.add('');
    }
    return createMultilineString(displayPoints, [], '', '', [], 5, false);
  }

  String getCurrentTotalPoints() {
    List<String> displayTotals = [];
    for (int i = 0; i < currentRound; i++) {
      displayTotals.add('${totalPoints[i]}');
    }
    if (currentRound < totalRounds) {
      displayTotals.add('');
    }
    return createMultilineString(displayTotals, [], '', '', [], 5, false);
  }

  @override
  bool isButtonDisabled(int value) {
    if (currentRound >= totalRounds) return true;
    if (value == -2) return hitCounts.isEmpty;
    if (value >= 0 && value <= 3) return false;
    if (value == -1) return false;
    return true;
  }

  @override
  void correctDarts(int value) {}

  @override
  String getInput() {
    return '';
  }

  String getStats() {
    int numberGames =
        statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordRoundPoints =
        statsService.getStat<int>('recordRoundPoints', defaultValue: 0)!;
    double longtermAverage =
        statsService.getStat<double>('longtermAverage', defaultValue: 0.0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'P': recordRoundPoints,
      },
      averages: {
        'P': longtermAverage,
      },
    );
  }
}
