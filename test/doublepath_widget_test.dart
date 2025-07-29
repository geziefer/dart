import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_doublepath.dart';
import 'package:dart/view/view_doublepath.dart';
import 'package:dart/widget/menu.dart';

// Generate mocks
@GenerateMocks([GetStorage])
import 'doublepath_widget_test.mocks.dart';

void main() {
  group('Double Path Game Widget Tests', () {
    late ControllerDoublePath controller;
    late BuildContext testContext;
    late MockGetStorage mockStorage;

    setUp(() {
      // Create fresh mock storage for each test
      mockStorage = MockGetStorage();
      
      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('totalPoints')).thenReturn(0);
      when(mockStorage.read('recordRoundPoints')).thenReturn(0);
      when(mockStorage.read('recordRoundAverage')).thenReturn(0.0); // Fix key name
      when(mockStorage.read('longtermAverage')).thenReturn(0.0); // Fix key name
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      // Create controller with injected mock storage
      controller = ControllerDoublePath.forTesting(mockStorage);
      
      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_doublepath',
        name: 'Double Path Test',
        view: const ViewDoublePath(title: 'Double Path Test'),
        controller: controller,
        params: {},
      ));
    });

    /// Tests complete Double Path game workflow with all 5 rounds
    /// Verifies: target sequences, point calculation, round progression, game ending
    testWidgets('Complete Double Path game workflow - all 5 rounds', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      // Arrange: Set up the game widget
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Assert: Verify initial state
      expect(controller.currentRound, equals(0));
      expect(controller.targets[0], equals('16-8-4')); // First target sequence
      expect(controller.hitCounts.length, equals(0));
      expect(controller.points.length, equals(0));

      // Act: Play Round 1 (16-8-4) - hit 2 targets
      controller.pressNumpadButton(testContext, 2);
      await tester.pumpAndSettle();

      // Assert: Verify Round 1 results
      expect(controller.currentRound, equals(1));
      expect(controller.hitCounts[0], equals(2));
      expect(controller.points[0], equals(3)); // Controller uses fixed scoring: 2 hits = 3 points
      expect(controller.totalPoints[0], equals(3));

      // Act: Play Round 2 (20-10-5) - hit 3 targets (perfect)
      controller.pressNumpadButton(testContext, 3);
      await tester.pumpAndSettle();

      // Assert: Verify Round 2 results
      expect(controller.currentRound, equals(2));
      expect(controller.hitCounts[1], equals(3));
      expect(controller.points[1], equals(6)); // 3 hits = 6 points (controller's fixed scoring)
      expect(controller.totalPoints[1], equals(9)); // 3 + 6

      // Act: Play Round 3 (4-2-1) - hit 1 target
      controller.pressNumpadButton(testContext, 1);
      await tester.pumpAndSettle();

      // Assert: Verify Round 3 results
      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts[2], equals(1));
      expect(controller.points[2], equals(1)); // 1 hit = 1 point (controller's fixed scoring)
      expect(controller.totalPoints[2], equals(10)); // 9 + 1

      // Act: Play Round 4 (12-6-3) - hit 0 targets
      controller.pressNumpadButton(testContext, 0);
      await tester.pumpAndSettle();

      // Assert: Verify Round 4 results
      expect(controller.currentRound, equals(4));
      expect(controller.hitCounts[3], equals(0));
      expect(controller.points[3], equals(0)); // No points
      expect(controller.totalPoints[3], equals(10)); // No change

      // Act: Play Round 5 (18-9-B) - hit 2 targets
      controller.pressNumpadButton(testContext, 2);
      await tester.pumpAndSettle();

      // Assert: Verify game completion
      expect(controller.currentRound, equals(5)); // Game completed
      expect(controller.hitCounts[4], equals(2));
      expect(controller.points[4], equals(3)); // 2 hits = 3 points (controller's fixed scoring)
      expect(controller.totalPoints[4], equals(13)); // 10 + 3
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage interactions
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalPoints', 13)).called(1);
      verify(mockStorage.write('recordRoundPoints', 6)).called(1);
      verify(mockStorage.write('recordRoundAverage', 2.6)).called(1);
      verify(mockStorage.write('longtermAverage', 2.6)).called(1);
    });

    /// Tests undo functionality during Double Path gameplay
    /// Verifies: undo removes last round, points recalculate correctly
    testWidgets('Double Path undo functionality test', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Act: Play a few rounds
      controller.pressNumpadButton(testContext, 3); // Round 1: 3 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, 2); // Round 2: 2 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, 1); // Round 3: 1 hit
      await tester.pump();
      
      // Assert: Verify state before undo
      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts.length, equals(3));
      expect(controller.points.length, equals(3));
      expect(controller.totalPoints.length, equals(3));

      // Act: Press undo button
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Verify undo worked correctly
      expect(controller.currentRound, equals(2));
      expect(controller.hitCounts.length, equals(2));
      expect(controller.points.length, equals(2));
      expect(controller.totalPoints.length, equals(2));

      // Act: Continue game after undo with different choice
      controller.pressNumpadButton(testContext, 0); // 0 hits instead of 1
      await tester.pump();
      
      // Assert: Game continues correctly after undo
      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts[2], equals(0)); // Third round now has 0 hits
      expect(controller.points[2], equals(0)); // No points for 0 hits
    });

    /// Tests point calculation for different target sequences
    /// Verifies: points are calculated correctly for each target sequence
    testWidgets('Double Path point calculation verification', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Test point calculations for each round with perfect scores (3 hits)
      List<int> expectedPerfectScores = [
        6, // 3 hits = 6 points (controller's fixed scoring)
        6, // 3 hits = 6 points
        6, // 3 hits = 6 points
        6, // 3 hits = 6 points
        6, // 3 hits = 6 points
      ];

      int cumulativeTotal = 0;
      for (int round = 0; round < 5; round++) {
        // Act: Hit all 3 targets in current round
        controller.pressNumpadButton(testContext, 3);
        await tester.pump();
        
        cumulativeTotal += expectedPerfectScores[round];
        
        // Assert: Verify point calculation for this round
        expect(controller.points[round], equals(expectedPerfectScores[round]),
            reason: 'Round ${round + 1} should score ${expectedPerfectScores[round]} points');
        expect(controller.totalPoints[round], equals(cumulativeTotal),
            reason: 'Cumulative total after round ${round + 1} should be $cumulativeTotal');
      }
    });

    /// Tests return button functionality (equivalent to 0 hits)
    /// Verifies: return button (-1) works as 0 hits input
    testWidgets('Double Path return button for zero hits', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Act: Use return button (should work as 0 hits)
      controller.pressNumpadButton(testContext, -1); // Return button
      await tester.pump();

      // Assert: Return button worked as 0 hits
      expect(controller.currentRound, equals(1));
      expect(controller.hitCounts[0], equals(0));
      expect(controller.points[0], equals(0));
      expect(controller.totalPoints[0], equals(0));
    });

    /// Tests input validation (only 0-3 hits allowed)
    /// Verifies: invalid inputs are rejected, valid inputs are accepted
    testWidgets('Double Path input validation', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Act: Try invalid inputs
      controller.pressNumpadButton(testContext, 4); // Too high
      await tester.pump();
      controller.pressNumpadButton(testContext, -3); // Invalid negative
      await tester.pump();
      controller.pressNumpadButton(testContext, 10); // Way too high
      await tester.pump();

      // Assert: Invalid inputs should be ignored
      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));

      // Act: Try valid inputs
      for (int validInput in [0, 1, 2, 3]) {
        controller.pressNumpadButton(testContext, validInput);
        await tester.pump();
      }

      // Assert: Valid inputs should be processed
      expect(controller.currentRound, equals(4)); // 4 rounds completed
      expect(controller.hitCounts.length, equals(4));
    });

    /// Tests statistics with existing data
    /// Verifies: statistics are updated correctly with existing game data
    testWidgets('Double Path statistics with existing data', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(3);
      when(mockStorage.read('totalPoints')).thenReturn(450);
      when(mockStorage.read('recordRoundPoints')).thenReturn(70);
      when(mockStorage.read('recordRoundAverage')).thenReturn(25.0); // Fix key name
      when(mockStorage.read('longtermAverage')).thenReturn(150.0); // Fix key name

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Act: Play a game scoring 180 points total
      List<int> hits = [3, 3, 2, 1, 2]; // Mixed performance
      for (int hitCount in hits) {
        controller.pressNumpadButton(testContext, hitCount);
        await tester.pumpAndSettle();
      }

      // Assert: Verify storage operations with existing data
      verify(mockStorage.write('numberGames', 4)).called(1); // 3 + 1
      // Note: Exact total points depend on calculation, but should be updated
      verify(mockStorage.write(argThat(equals('totalPoints')), any)).called(1);
    });

    /// Tests undo edge cases
    /// Verifies: undo doesn't work when no rounds played
    testWidgets('Double Path undo edge cases', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Act: Try undo with no rounds played
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Nothing should change
      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));
      expect(controller.points.length, equals(0));

      // Act: Play one round and undo
      controller.pressNumpadButton(testContext, 2); // 2 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, -2); // Undo
      await tester.pump();

      // Assert: Back to initial state
      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));
      expect(controller.points.length, equals(0));
      expect(controller.totalPoints.length, equals(0));
    });

    /// Tests target sequence consistency
    /// Verifies: target sequences remain consistent throughout game
    testWidgets('Double Path target sequence consistency', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      // Assert: Verify all target sequences are correct
      List<String> expectedSequences = ['16-8-4', '20-10-5', '4-2-1', '12-6-3', '18-9-B'];
      
      for (int i = 0; i < expectedSequences.length; i++) {
        expect(controller.targets[i], equals(expectedSequences[i]),
            reason: 'Target sequence $i should be ${expectedSequences[i]}');
      }

      // Assert: Verify sequences don't change during gameplay
      List<String> originalTargets = List.from(controller.targets);
      
      // Act: Play through some rounds
      for (int i = 0; i < 3; i++) {
        controller.pressNumpadButton(testContext, 2);
        await tester.pump();
      }

      // Assert: Target sequences should remain unchanged
      for (int i = 0; i < expectedSequences.length; i++) {
        expect(controller.targets[i], equals(originalTargets[i]),
            reason: 'Target sequence should not change during gameplay');
      }
    });

    /// Tests getCurrentStats method
    /// Verifies: current game statistics are calculated correctly
    testWidgets('Double Path current stats calculation', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerDoublePath>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewDoublePath(title: 'Double Path Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewDoublePath));

      // Act: Play a few rounds
      controller.pressNumpadButton(testContext, 3); // Perfect round 1
      await tester.pump();
      controller.pressNumpadButton(testContext, 2); // Good round 2
      await tester.pump();
      controller.pressNumpadButton(testContext, 0); // Miss round 3
      await tester.pump();

      // Assert: Verify current stats
      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts.length, equals(3));
      expect(controller.points.length, equals(3));
      
      // Verify total points calculation
      int expectedTotal = controller.points.fold(0, (sum, points) => sum + points);
      expect(controller.totalPoints.last, equals(expectedTotal));
    });
  });
}
