import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

class ControllerPlanHit extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  ControllerPlanHit({GetStorage? storage}) : _injectedStorage = storage;

  factory ControllerPlanHit.create() {
    return ControllerPlanHit();
  }

  factory ControllerPlanHit.forTesting(GetStorage storage) {
    return ControllerPlanHit(storage: storage);
  }

  MenuItem? item;

  List<String> targets = <String>[];
  List<int> hitCounts = <int>[];
  List<int> totalHits = <int>[];
  int currentRound = 0;
  final Random _random = Random();

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);

    targets = <String>[];
    hitCounts = <int>[];
    totalHits = <int>[];
    currentRound = 0;
    
    for (int i = 0; i < 10; i++) {
      targets.add(_generateTargetSequence());
    }
    
    notifyListeners();
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  String _generateTargetSequence() {
    List<int> numbers = List.generate(3, (_) => _random.nextInt(20) + 1);
    return numbers.join('-');
  }

  @override
  void pressNumpadButton(int value) {
    if (value == -2) {
      if (hitCounts.isNotEmpty) {
        hitCounts.removeLast();
        totalHits.removeLast();
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

    hitCounts.add(hits);
    int total = hitCounts.fold(0, (sum, h) => sum + h);
    totalHits.add(total);
    currentRound++;

    if (currentRound >= 10) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        triggerGameEnd();
      });
    }

    notifyListeners();
  }

  @override
  void updateSpecificStats() {
    int gameTotal = totalHits.isNotEmpty ? totalHits.last : 0;
    double gameAverage = gameTotal / 10.0;

    // Update cumulative stats
    int totalGamePoints = statsService.getStat<int>('totalPoints', defaultValue: 0)!;
    statsService.updateStats({'totalPoints': totalGamePoints + gameTotal});

    // Update records
    statsService.updateRecord<int>('recordPoints', gameTotal);
    statsService.updateRecord<double>('recordAverage', gameAverage);

    // Update long-term average
    statsService.updateLongTermAverage('longtermAverage', gameAverage);
  }

  String getStats() {
    int numberGames = statsService.getStat<int>('numberGames', defaultValue: 0)!;
    int recordPoints = statsService.getStat<int>('recordPoints', defaultValue: 0)!;
    double longtermAverage = statsService.getStat<double>('longtermAverage', defaultValue: 0.0)!;

    return formatStatsString(
      numberGames: numberGames,
      records: {
        'P': recordPoints,
      },
      averages: {
        'P': longtermAverage,
      },
    );
  }

  @override
  List<SummaryLine> createSummaryLines() {
    int totalScore = totalHits.isNotEmpty ? totalHits.last : 0;
    double averagePerRound = totalScore / 10.0;

    return [
      SummaryService.createValueLine('Punkte', totalScore, emphasized: true),
      SummaryService.createAverageLine('Punkte pro Runde', averagePerRound),
    ];
  }

  @override
  String getInput() => '';

  @override
  void correctDarts(int value) {}

  @override
  bool isButtonDisabled(int value) {
    if (currentRound >= 10) return true;
    return !(value >= 0 && value <= 3) && value != -1 && value != -2;
  }

  String getCurrentTargets() {
    List<String> displayTargets = [];
    int roundsToShow = currentRound < 10 ? currentRound + 1 : currentRound;
    for (int i = 0; i < roundsToShow; i++) {
      displayTargets.add(targets[i]);
    }
    return createMultilineString(displayTargets, [], '', '', [], 5, false);
  }

  String getCurrentHits() {
    List<String> displayHits = [];
    for (int i = 0; i < currentRound; i++) {
      displayHits.add('${hitCounts[i]}');
    }
    if (currentRound < 10) {
      displayHits.add('');
    }
    return createMultilineString(displayHits, [], '', '', [], 5, false);
  }

  String getCurrentTotalHits() {
    List<String> displayTotals = [];
    for (int i = 0; i < currentRound; i++) {
      displayTotals.add('${totalHits[i]}');
    }
    if (currentRound < 10) {
      displayTotals.add('');
    }
    return createMultilineString(displayTotals, [], '', '', [], 5, false);
  }
}
