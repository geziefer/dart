import 'package:dart/controller/controller_challenge.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Challenge Widget Tests', () {
    testWidgets('Challenge controller initializes correctly', (WidgetTester tester) async {
      // Create controller and menu item
      final controller = ControllerChallenge();
      final menuItem = MenuItem(
        id: 'challenge',
        name: 'Challenge',
        view: const SizedBox(), // Simple widget for testing
        getController: (_) => controller,
        params: {},
      );

      // Initialize controller
      controller.init(menuItem);

      // Verify initialization
      expect(controller.currentStage, equals(0));
      expect(controller.currentController, isNotNull);
      expect(controller.stageResults, equals([0, 0, 0, 0, 0]));
    });

    testWidgets('Challenge calculates badge correctly', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      
      // Test bronze badge (just meets thresholds)
      controller.stageResults = [2, 2, 2, 1, 80];
      String badge = controller.calculateBadge();
      expect(badge, equals('🥉'));

      // Test no badge (shoot bull too low: 0 < 1)
      controller.stageResults = [2, 2, 2, 0, 80];
      badge = controller.calculateBadge();
      expect(badge, equals('😢'));

      // Test gold+ badge
      controller.stageResults = [14, 14, 28, 16, 24];
      badge = controller.calculateBadge();
      expect(badge, equals('🥇+'));
    });

    testWidgets('Challenge resets state on initialization', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      final menuItem = MenuItem(
        id: 'challenge',
        name: 'Challenge',
        view: const SizedBox(),
        getController: (_) => controller,
        params: {},
      );

      // Simulate previous game state
      controller.currentStage = 3;
      controller.stageResults = [10, 8, 15, 12, 35];

      // Re-initialize
      controller.init(menuItem);

      // Verify reset
      expect(controller.currentStage, equals(0));
      expect(controller.stageResults, equals([0, 0, 0, 0, 0]));
    });

    testWidgets('Challenge stage advancement works', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      final menuItem = MenuItem(
        id: 'challenge',
        name: 'Challenge',
        view: const SizedBox(),
        getController: (_) => controller,
        params: {},
      );

      controller.init(menuItem);

      // Simulate completing stages and wait for timers
      controller.onStageCompleted(10); // Stage 0 -> 1
      await tester.pump(const Duration(milliseconds: 600)); // Wait for timer
      expect(controller.currentStage, equals(1));
      expect(controller.stageResults[0], equals(10));

      controller.onStageCompleted(8); // Stage 1 -> 2
      await tester.pump(const Duration(milliseconds: 600)); // Wait for timer
      expect(controller.currentStage, equals(2));
      expect(controller.stageResults[1], equals(8));

      controller.onStageCompleted(15); // Stage 2 -> 3
      await tester.pump(const Duration(milliseconds: 600)); // Wait for timer
      expect(controller.currentStage, equals(3));
      expect(controller.stageResults[2], equals(15));
    });

    testWidgets('Challenge creates correct final summary lines', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      
      // Set completed challenge results
      controller.currentStage = 5;
      controller.stageResults = [10, 8, 15, 12, 35];

      final summaryLines = controller.createSummaryLines();
      
      expect(summaryLines.length, equals(2));
      expect(summaryLines[0].label, equals('MATRIX'));
      expect(summaryLines[0].isMatrix, equals(true));
      expect(summaryLines[1].isFinalBadge, equals(true));
      // Badge should be calculated based on the results
      expect(summaryLines[1].value, isNotEmpty);
    });

    testWidgets('Challenge badge calculation edge cases', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      
      // Test silver badge - need to meet all requirements at index 2
      // RTCX: 6+6=12 (≥6), Shoot20: 6 (≥6), ShootBull: 4 (≥4), Checkout: 48 (≤48)
      controller.stageResults = [6, 6, 6, 4, 48];
      expect(controller.calculateBadge(), equals('🥈'));
      
      // Test silver+ badge - higher requirements at index 3
      // RTCX: 12+12=24 (≥12), Shoot20: 12 (≥12), ShootBull: 8 (≥8), Checkout: 39 (≤39)
      controller.stageResults = [12, 12, 12, 8, 39];
      expect(controller.calculateBadge(), equals('🥈+'));
    });

    testWidgets('Challenge stage names and progression', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      
      expect(controller.stageNames.length, equals(5));
      expect(controller.stageNames[0], contains('RTCX'));
      expect(controller.stageNames[4], contains('501'));
    });

    testWidgets('Challenge controller interface methods', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      
      expect(controller.getInput(), equals(''));
      expect(controller.getStats(), isNotEmpty);
      expect(controller.getCurrentStats(), isA<Map<String, String>>());
    });

    testWidgets('Challenge numpad button handling', (WidgetTester tester) async {
      final controller = ControllerChallenge();
      final menuItem = MenuItem(
        id: 'challenge',
        name: 'Challenge',
        view: const SizedBox(),
        getController: (_) => controller,
        params: {},
      );
      controller.init(menuItem);
      
      // Test that numpad buttons are delegated to current controller
      expect(controller.currentController, isNotNull);
    });
  });
}
