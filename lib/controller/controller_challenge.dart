import 'package:dart/controller/controller_base.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';

class ControllerChallenge extends ControllerBase
    implements MenuitemController, NumpadController {
  MenuItem? item;

  // Challenge state
  int currentStage = 0; // 0-4 for the 5 stages
  List<String> stageNames = [
    'RTCX Singles (1/2)',
    'RTCX Singles (2/2)',
    'Shoot 20 (10 rounds)',
    'Shoot Bull (10 rounds)',
    '501 Checkout'
  ];

  // Results from each stage
  List<int> stageResults = [
    0,
    0,
    0,
    0,
    0
  ]; // rtcx1, rtcx2, shoot20, shootbull, checkout501

  // Current sub-controller
  dynamic currentController;

  // Badge thresholds [bronze, bronze+, silver, silver+, gold, gold+]
  static const List<List<int>> badgeThresholds = [
    [2, 4, 6, 12, 20, 28], // RTCX total hits (sum of 2 rounds)
    [2, 4, 6, 12, 20, 28], // Shoot 20 points
    [1, 2, 4, 8, 12, 16], // Shoot Bull points
    [80, 60, 48, 39, 30, 24], // 501 Checkout darts (lower is better)
  ];

  static const List<String> badgeNames = [
    '🥉',
    '🥉+',
    '🥈',
    '🥈+',
    '🥇',
    '🥇+'
  ];

  @override
  void init(MenuItem item) {
    this.item = item;
    // No storage service needed for challenge

    // Reset challenge state for fresh start
    currentStage = 0;
    stageResults = List.filled(5, 0);
    currentController = null;

    // Start the first stage
    startNextStage();
  }

  @override
  void initFromProvider(MenuItem item) {
    init(item); // This will reset state and start fresh
  }

  void startNextStage() {
    if (currentStage >= 5) {
      // All stages completed - show final summary
      showFinalSummary();
      return;
    }

    // Create appropriate controller for current stage
    switch (currentStage) {
      case 0:
      case 1:
        // RTCX Singles
        currentController = ControllerRTCX.create();
        currentController.init(MenuItem(
          id: 'challenge_rtcx_$currentStage',
          name: 'RTCX Singles',
          view: const SizedBox(),
          getController: (_) => currentController,
          params: {'max': 7}, // Fixed 7 rounds (20 numbers / 3 darts per round)
        ));
        currentController.skipLongtermStorage = true;
        currentController.onGameCompleted = onStageCompleted;
        currentController.challengeStepInfo =
            'Bayrisches Sportabzeichen - Schritt ${currentStage + 1}/5';
        currentController.notifyListeners(); // Force UI refresh
        break;
      case 2:
        // Shoot 20
        currentController = ControllerShootx.create();
        currentController.skipLongtermStorage = true;
        currentController.onGameCompleted = onStageCompleted;
        currentController.challengeStepInfo =
            'Bayrisches Sportabzeichen - Schritt ${currentStage + 1}/5';
        currentController.init(MenuItem(
          id: 'challenge_shoot20',
          name: 'Shoot 20',
          view: const SizedBox(),
          getController: (_) => currentController,
          params: {'x': 20, 'max': 10},
        ));
        currentController.notifyListeners();
        break;
      case 3:
        // Shoot Bull
        currentController = ControllerShootx.create();
        currentController.skipLongtermStorage = true;
        currentController.onGameCompleted = onStageCompleted;
        currentController.challengeStepInfo =
            'Bayrisches Sportabzeichen - Schritt ${currentStage + 1}/5';
        currentController.init(MenuItem(
          id: 'challenge_shootbull',
          name: 'Shoot Bull',
          view: const SizedBox(),
          getController: (_) => currentController,
          params: {'x': 25, 'max': 10},
        ));
        currentController.notifyListeners();
        break;
      case 4:
        // 501 Checkout
        currentController = ControllerXXXCheckout.create();
        currentController.skipLongtermStorage = true;
        currentController.onGameCompleted = onStageCompleted;
        currentController.challengeStepInfo =
            'Bayrisches Sportabzeichen - Schritt ${currentStage + 1}/5';
        currentController.init(MenuItem(
          id: 'challenge_501',
          name: '501 Checkout',
          view: const SizedBox(),
          getController: (_) => currentController,
          params: {'xxx': 501, 'max': -1, 'end': 1},
        ));
        currentController.notifyListeners();
        break;
    }

    notifyListeners();
  }

  void onStageCompleted(int result) {
    stageResults[currentStage] = result;
    currentStage++;

    // Small delay before starting next stage to allow summary dialog to close
    Future.delayed(const Duration(milliseconds: 500), () {
      startNextStage();
    });
  }

  void advanceToNextStage() {
    currentStage++;
    if (currentStage < 5) {
      // Start next stage
      startNextStage();
      notifyListeners();
    } else {
      // All stages complete - show final summary
      showFinalSummary();
    }
  }

  void showFinalSummary() {
    onGameEnded?.call();
  }

  String calculateBadge() {
    int rtcxTotal = stageResults[0] + stageResults[1];
    int shoot20 = stageResults[2];
    int shootBull = stageResults[3];
    int checkout501 = stageResults[4];

    // Find highest badge where all requirements are met
    for (int i = badgeThresholds[0].length - 1; i >= 0; i--) {
      bool qualifies = true;

      // Check RTCX requirement
      if (rtcxTotal < badgeThresholds[0][i]) qualifies = false;

      // Check Shoot 20 requirement
      if (shoot20 < badgeThresholds[1][i]) qualifies = false;

      // Check Shoot Bull requirement
      if (shootBull < badgeThresholds[2][i]) qualifies = false;

      // Check 501 Checkout requirement (lower is better)
      if (checkout501 > badgeThresholds[3][i]) qualifies = false;

      if (qualifies) {
        return badgeNames[i];
      }
    }

    return '😢';
  }

  // Delegate all numpad operations to current controller
  @override
  void pressNumpadButton(int value) {
    currentController?.pressNumpadButton(value);
  }

  @override
  void correctDarts(int darts) {
    currentController?.correctDarts(darts);
  }

  @override
  String getInput() {
    return currentController?.getInput() ?? '';
  }

  @override
  bool isButtonDisabled(int value) {
    return currentController?.isButtonDisabled(value) ?? false;
  }

  // Challenge-specific display methods
  String getCurrentStage() {
    return currentStage < stageNames.length
        ? stageNames[currentStage]
        : 'Complete';
  }

  String getProgress() {
    return '${currentStage + 1}/5';
  }

  // Delegate stats to current controller but modify display
  Map<String, String> getCurrentStats() {
    if (currentController == null) {
      return {
        'challenge': 'Challenge: ${getCurrentStage()}',
        'progress': 'Step: ${getProgress()}',
      };
    }

    try {
      var rawStats = currentController.getCurrentStats();
      Map<String, String> stats = {};

      if (rawStats != null) {
        rawStats.forEach((key, value) {
          stats[key.toString()] = value.toString();
        });
      }

      // Add challenge progress
      stats['challenge'] = 'Challenge: ${getCurrentStage()}';
      stats['progress'] = 'Step: ${getProgress()}';

      return stats;
    } catch (e) {
      return {
        'challenge': 'Challenge: ${getCurrentStage()}',
        'progress': 'Step: ${getProgress()}',
        'error': 'Stats unavailable',
      };
    }
  }

  String getStats() {
    // No persistent stats for challenge
    return 'Challenge Mode - No Statistics';
  }

  @override
  List<SummaryLine> createSummaryLines() {
    if (currentStage >= 5) {
      // Final summary
      String badge = calculateBadge();
      return [
        SummaryLine('Big Single', '${stageResults[0] + stageResults[1]}'),
        SummaryLine('Shoot 20', '${stageResults[2]}'),
        SummaryLine('Shoot Bull', '${stageResults[3]}'),
        SummaryLine('501', '${stageResults[4]}'),
        SummaryLine('Abzeichen', badge, emphasized: true),
      ];
    }

    // Delegate to current controller for individual stage summaries
    return currentController?.createSummaryLines() ?? [];
  }

  @override
  void updateSpecificStats() {
    // No stats to update for challenge
  }
}
