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
      
      expect(summaryLines.length, equals(5));
      expect(summaryLines[0].label, equals('Big Single'));
      expect(summaryLines[0].value, equals('18')); // 10 + 8
      expect(summaryLines[1].label, equals('Shoot 20'));
      expect(summaryLines[1].value, equals('15'));
      expect(summaryLines[2].label, equals('Shoot Bull'));
      expect(summaryLines[2].value, equals('12'));
      expect(summaryLines[3].label, equals('501'));
      expect(summaryLines[3].value, equals('35'));
      expect(summaryLines[4].label, equals('Abzeichen'));
      expect(summaryLines[4].emphasized, isTrue);
    });
  });
}
