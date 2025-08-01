import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';

class ControllerFinishes extends ControllerBase
    implements MenuitemController, DartboardController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerFinishes({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerFinishes.create() {
    return ControllerFinishes();
  }

  // Factory for testing with injected storage
  factory ControllerFinishes.forTesting(GetStorage storage) {
    return ControllerFinishes(storage: storage);
  }

  static final Map<int, List<List<String>>> finishes = {
    170: [
      ["T20", "T20", "DB"],
      []
    ],
    167: [
      ["T20", "T19", "DB"],
      []
    ],
    164: [
      ["T19", "T19", "DB"],
      []
    ],
    161: [
      ["T20", "T17", "DB"],
      []
    ],
    160: [
      ["T20", "T20", "D20"],
      []
    ],
    158: [
      ["T20", "T20", "D19"],
      []
    ],
    157: [
      ["T20", "T19", "D20"],
      []
    ],
    156: [
      ["T20", "T20", "D18"],
      []
    ],
    155: [
      ["T20", "T19", "D19"],
      []
    ],
    154: [
      ["T19", "T19", "D20"],
      []
    ],
    153: [
      ["T20", "T19", "D18"],
      []
    ],
    152: [
      ["T20", "T20", "D16"],
      []
    ],
    151: [
      ["T20", "T17", "D20"],
      []
    ],
    150: [
      ["T19", "T19", "D18"],
      []
    ],
    149: [
      ["T20", "T19", "D16"],
      []
    ],
    148: [
      ["T18", "T18", "D20"],
      []
    ],
    147: [
      ["T20", "T17", "D18"],
      []
    ],
    146: [
      ["T19", "T19", "D16"],
      []
    ],
    145: [
      ["T20", "T15", "D20"],
      []
    ],
    144: [
      ["T20", "T20", "D12"],
      []
    ],
    143: [
      ["T20", "T17", "D16"],
      []
    ],
    142: [
      ["T17", "T17", "D20"],
      []
    ],
    141: [
      ["T20", "T19", "D12"],
      []
    ],
    140: [
      ["T18", "T18", "D16"],
      []
    ],
    139: [
      ["T19", "T14", "D20"],
      []
    ],
    138: [
      ["T19", "T19", "D12"],
      []
    ],
    137: [
      ["T20", "T15", "D16"],
      []
    ],
    136: [
      ["T20", "T20", "D8"],
      []
    ],
    135: [
      ["DB", "T15", "D20"],
      ["SB", "T20", "DB"]
    ],
    134: [
      ["T20", "T14", "D16"],
      []
    ],
    133: [
      ["T20", "T19", "D8"],
      []
    ],
    132: [
      ["DB", "T14", "D20"],
      ["SB", "T19", "DB"]
    ],
    131: [
      ["T20", "T13", "D16"],
      []
    ],
    130: [
      ["T20", "T20", "D5"],
      ["S20", "T20", "DB"]
    ],
    129: [
      ["T19", "T16", "D12"],
      ["S19", "T20", "DB"]
    ],
    128: [
      ["T18", "T18", "D10"],
      ["S18", "T20", "DB"]
    ],
    127: [
      ["T20", "T17", "D8"],
      ["S20", "T19", "DB"]
    ],
    126: [
      ["T19", "T19", "D6"],
      ["S19", "T19", "DB"]
    ],
    125: [
      ["DB", "T17", "D12"],
      ["SB", "T20", "D20"]
    ],
    124: [
      ["T20", "T16", "D8"],
      ["S20", "T18", "DB"]
    ],
    123: [
      ["T19", "T16", "D9"],
      ["S19", "T18", "DB"]
    ],
    122: [
      ["T18", "T18", "D7"],
      ["S18", "T18", "DB"]
    ],
    121: [
      ["T20", "T11", "D14"],
      ["S20", "T17", "DB"]
    ],
    120: [
      ["T20", "S20", "D20"],
      ["S20", "T20", "D20"]
    ],
    119: [
      ["T19", "T12", "D13"],
      ["S19", "T20", "D20"]
    ],
    118: [
      ["T20", "S18", "D20"],
      ["S20", "T20", "D19"]
    ],
    117: [
      ["T20", "S17", "D20"],
      ["S20", "T19", "D20"]
    ],
    116: [
      ["T20", "S16", "D20"],
      ["S20", "T20", "D18"]
    ],
    115: [
      ["T20", "S15", "D20"],
      ["S20", "T19", "D19"]
    ],
    114: [
      ["T20", "S14", "D20"],
      ["S20", "T18", "D20"]
    ],
    113: [
      ["T19", "S16", "D20"],
      ["S19", "T18", "D20"]
    ],
    112: [
      ["T20", "S12", "D20"],
      ["S20", "T20", "D16"]
    ],
    111: [
      ["T20", "S11", "D20"],
      ["S20", "T17", "D20"]
    ],
    110: [
      ["T20", "S10", "D20"],
      ["S20", "T18", "D18"]
    ],
    109: [
      ["T19", "S20", "D16"],
      ["S19", "T18", "D18"]
    ],
    108: [
      ["T20", "S16", "D16"],
      ["S20", "T20", "D14"]
    ],
    107: [
      ["T19", "S18", "D16"],
      ["S19", "T20", "D19"]
    ],
    106: [
      ["T20", "S14", "D16"],
      ["S20", "T18", "D16"]
    ],
    105: [
      ["T20", "S13", "D16"],
      ["S20", "T18", "D16"]
    ],
    104: [
      ["T19", "S15", "D16"],
      ["S19", "T15", "D20"]
    ],
    103: [
      ["T19", "S14", "D16"],
      ["S19", "T20", "D12"]
    ],
    102: [
      ["T20", "S10", "D16"],
      ["S20", "T14", "D20"]
    ],
    101: [
      ["T20", "S9", "D16"],
      ["S20", "T17", "D15"]
    ],
    100: [
      ["T20", "D20"],
      ["S20", "D20", "D20"]
    ],
    99: [
      ["T19", "S10", "D16"],
      ["S19", "D20", "D20"]
    ],
    98: [
      ["T20", "D19"],
      ["S20", "T18", "D12"]
    ],
    97: [
      ["T19", "D20"],
      ["S19", "T18", "D12"]
    ],
    96: [
      ["T20", "D18"],
      ["S20", "T20", "D8"]
    ],
    95: [
      ["T19", "D19"],
      ["S19", "T20", "D8"]
    ],
    94: [
      ["T18", "D20"],
      ["S18", "T20", "D8"]
    ],
    93: [
      ["T19", "D18"],
      ["S19", "T14", "D16"]
    ],
    92: [
      ["T20", "D16"],
      ["S20", "T16", "D12"]
    ],
    91: [
      ["T17", "D20"],
      ["S17", "T14", "D16"]
    ],
    90: [
      ["T20", "D15"],
      ["S20", "S20", "DB"]
    ],
    89: [
      ["T19", "D16"],
      ["S19", "S20", "DB"]
    ],
    88: [
      ["T20", "D14"],
      ["S20", "T20", "D4"]
    ],
    87: [
      ["T17", "D18"],
      ["S17", "S20", "DB"]
    ],
    86: [
      ["T18", "D16"],
      ["S18", "T20", "D4"]
    ],
    85: [
      ["T15", "D20"],
      ["S15", "S20", "DB"]
    ],
    84: [
      ["T20", "D12"],
      ["S20", "S14", "DB"]
    ],
    83: [
      ["T17", "D16"],
      ["S17", "S16", "DB"]
    ],
    82: [
      ["DB", "D16"],
      ["SB", "S17", "D20"]
    ],
    81: [
      ["T15", "D18"],
      ["S15", "S16", "DB"]
    ],
    80: [
      ["T20", "D10"],
      ["S20", "S20", "D20"]
    ],
    79: [
      ["T19", "D11"],
      ["S19", "S20", "D20"]
    ],
    78: [
      ["T18", "D12"],
      ["S18", "S20", "D20"]
    ],
    77: [
      ["T19", "D10"],
      ["S19", "S18", "D20"]
    ],
    76: [
      ["T20", "D8"],
      ["S20", "S16", "D20"]
    ],
    75: [
      ["T17", "D12"],
      ["S17", "S18", "D20"]
    ],
    74: [
      ["T14", "D16"],
      ["S14", "S20", "D20"]
    ],
    73: [
      ["T19", "D8"],
      ["S19", "S14", "D20"]
    ],
    72: [
      ["T16", "D12"],
      ["S16", "S16", "D20"]
    ],
    71: [
      ["T13", "D16"],
      ["S13", "S18", "D20"]
    ],
    70: [
      ["T18", "D8"],
      ["S18", "S20", "D16"]
    ],
    69: [
      ["T15", "D12"],
      ["S15", "S14", "D20"]
    ],
    68: [
      ["T20", "D4"],
      ["S20", "S16", "D16"]
    ],
    67: [
      ["T17", "D8"],
      ["S17", "S18", "D16"]
    ],
    66: [
      ["T10", "D18"],
      ["S10", "S16", "D20"]
    ],
    65: [
      ["SB", "D20"],
      ["DB", "S7", "D4"]
    ],
    64: [
      ["T16", "D8"],
      ["S16", "S16", "D16"]
    ],
    63: [
      ["T13", "D12"],
      ["S13", "S18", "D16"]
    ],
    62: [
      ["T10", "D16"],
      ["S10", "S20", "D16"]
    ],
    61: [
      ["T15", "D8"],
      ["S15", "S14", "D16"]
    ],
  };

  MenuItem? item; // item which created the controller
  // will be initialized in init or indirectly in createRandomFiish()
  int from = 0;
  int to = 0;
  int currentFinish = 0;
  List<String> preferred = [];
  List<String> alternative = [];
  List<String> preferredInput = [];
  List<String> altervativeInput = [];
  String correctSymbol = "";
  String stoppedTime = "";
  FinishesState currentState = FinishesState.inputPreferred;
  Stopwatch stopwatch = Stopwatch();

  // Session tracking variables
  int currentRound = 1;
  int correctRounds = 0;
  int totalTimeSeconds = 0; // Track total time spent in all completed rounds
  static const int maxRounds = 10;

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    initializeServices(_storageService!);
    from = item.params['from'];
    to = item.params['to'];

    // Initialize session
    currentRound = 1;
    correctRounds = 0;
    totalTimeSeconds = 0;

    _createRandomFinish();
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item);
  }

  void _createRandomFinish() {
    var r = Random();

    // Get all available finishes in the range
    List<int> availableFinishes = finishes.keys
        .where((finish) => finish >= from && finish <= to)
        .toList();

    // Select random finish from available ones
    int finish = availableFinishes[r.nextInt(availableFinishes.length)];

    currentFinish = finish;
    preferred = finishes[currentFinish]![0];
    alternative = finishes[currentFinish]![1];
    preferredInput = List.empty(growable: true);
    altervativeInput = List.empty(growable: true);
    correctSymbol = "";
    stoppedTime = "";
    currentState = FinishesState.inputPreferred;
    stopwatch.reset();
    stopwatch.start();
  }

  String getPreferredText() {
    return "Finish ${currentFinish.toString()}:";
  }

  String getRoundCounterText() {
    return "Runde $currentRound";
  }

  String getPreferredInput() {
    return preferredInput.join(' ');
  }

  String getAlternativeText() {
    return currentState == FinishesState.inputAlternative ||
            currentState == FinishesState.solution
        ? "Alternative ${currentFinish.toString()}:"
        : "";
  }

  String getAlternativeInput() {
    return altervativeInput.join(' ');
  }

  String getResultSymbol() {
    return correctSymbol;
  }

  String getResultTime() {
    return stoppedTime;
  }

  String _getStoppedTime() {
    return stopwatch.isRunning ? "" : "${stopwatch.elapsed.inSeconds}s";
  }

  String getSolutionText() {
    return currentState == FinishesState.solution && correctSymbol == "❌"
        ? "${preferred.join(' ')}\n${alternative.join(' ')}"
        : "";
  }

  @override
  void pressDartboard(String value) {
    switch (currentState) {
      case FinishesState.inputPreferred:
        preferredInput.add(value);
        if (preferredInput.length == preferred.length) {
          currentState = FinishesState.inputAlternative;
          if (alternative.isEmpty) {
            currentState = FinishesState.solution;
            _checkCorrect();
          }
        }
        break;
      case FinishesState.inputAlternative:
        altervativeInput.add(value);
        if (altervativeInput.length == alternative.length) {
          stopwatch.stop();
          _checkCorrect();
          currentState = FinishesState.solution;
        }
      case FinishesState.solution:
        // Check if session is complete
        if (currentRound >= maxRounds) {
          // Use post-frame callback to avoid context across async gaps
          WidgetsBinding.instance.addPostFrameCallback((_) {
            triggerGameEnd();
          });
        } else {
          // Continue to next round
          currentRound++;
          _createRandomFinish();
          currentState = FinishesState.inputPreferred;
        }
    }
    notifyListeners();
  }

  // Show summary dialog using SummaryDialog widget

  @override
  List<SummaryLine> createSummaryLines() {
    double correctnessPercentage = (correctRounds / maxRounds) * 100;
    double averageTime = _getAverageTime();

    return [
      SummaryService.createValueLine('Richtige Runden', '$correctRounds/$maxRounds'),
      SummaryService.createAverageLine('Korrektheit', correctnessPercentage, emphasized: true),
      SummaryService.createAverageLine('ØZeit/Runde', averageTime, emphasized: true),
    ];
  }

  @override
  String getGameTitle() => 'Finishes';

  @override
  void updateSpecificStats() {
    double correctnessPercentage = (correctRounds / maxRounds) * 100;
    double averageTime = _getAverageTime();
    
    // Update cumulative stats
    int totalCorrectRounds = statsService.getStat<int>('totalCorrectRounds', defaultValue: 0)!;
    int totalRounds = statsService.getStat<int>('totalRounds', defaultValue: 0)!;
    int totalTimeAllGames = statsService.getStat<int>('totalTimeAllGames', defaultValue: 0)!;
    
    statsService.updateStats({
      'totalCorrectRounds': totalCorrectRounds + correctRounds,
      'totalRounds': totalRounds + maxRounds,
      'totalTimeAllGames': totalTimeAllGames + totalTimeSeconds,
    });
    
    // Calculate overall stats
    double overallPercentage = (totalRounds + maxRounds) > 0
        ? ((totalCorrectRounds + correctRounds) / (totalRounds + maxRounds)) * 100
        : correctnessPercentage;
    double overallAverageTime = (totalRounds + maxRounds) > 0
        ? ((totalTimeAllGames + totalTimeSeconds) / (totalRounds + maxRounds))
        : averageTime;
    
    statsService.updateStats({
      'overallPercentage': overallPercentage,
      'overallAverageTime': overallAverageTime,
    });
    
    // Update records
    statsService.updateRecord<double>('recordPercentage', correctnessPercentage);
    // For time, lower is better
    double recordAverageTime = statsService.getStat<double>('recordAverageTime', defaultValue: 0.0)!;
    if (recordAverageTime == 0.0 || averageTime < recordAverageTime) {
      statsService.updateStats({'recordAverageTime': averageTime});
    }
  }

  Map getCurrentStats() {
    int completedRounds = currentRound - 1;
    double currentPercentage =
        completedRounds > 0 ? (correctRounds / completedRounds) * 100 : 0.0;
    double averageTime =
        completedRounds > 0 ? (totalTimeSeconds / completedRounds) : 0.0;

    return {
      'round': currentRound,
      'correct': correctRounds,
      'percentage': currentPercentage.toStringAsFixed(1),
      'totalTime': totalTimeSeconds,
      'averageTime': averageTime.toStringAsFixed(1),
    };
  }

  double _getAverageTime() {
    int completedRounds = currentRound - 1;
    return completedRounds > 0 ? (totalTimeSeconds / completedRounds) : 0.0;
  }

  String getStats() {
    int numberGames = statsService.getStat<int>('numberGames', defaultValue: 0)!;
    double recordPercentage = statsService.getStat<double>('recordPercentage', defaultValue: 0.0)!;
    double recordAverageTime = statsService.getStat<double>('recordAverageTime', defaultValue: 0.0)!;
    double overallPercentage = statsService.getStat<double>('overallPercentage', defaultValue: 0.0)!;
    double overallAverageTime = statsService.getStat<double>('overallAverageTime', defaultValue: 0.0)!;

    // Format percentages with % symbol and times with s suffix
    String baseStats = formatStatsString(
      numberGames: numberGames,
      records: {
        'P': '${recordPercentage.toStringAsFixed(1)}%',      // Prozent
        'Z': '${recordAverageTime.toStringAsFixed(1)}s',     // Zeit
      },
      averages: {
        'P': '${overallPercentage.toStringAsFixed(1)}%',     // Durchschnittsprozent
        'Z': '${overallAverageTime.toStringAsFixed(1)}s',    // Durchschnittszeit
      },
    );
    return baseStats;
  }

  void _checkCorrect() {
    const listEquality = ListEquality();
    bool isCorrect = listEquality.equals(preferred, preferredInput) &&
        listEquality.equals(alternative, altervativeInput);

    // Add current round time to total
    totalTimeSeconds += stopwatch.elapsed.inSeconds;

    // Always display the time, regardless of correctness
    stoppedTime = _getStoppedTime();

    if (isCorrect) {
      correctRounds++;
      correctSymbol = "✅";
    } else {
      correctSymbol = "❌";
    }
  }
}

enum FinishesState { inputPreferred, inputAlternative, solution }
