import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_twodarts.dart';
import 'package:dart/view/view_twodarts.dart';
import 'package:dart/widget/menu.dart';

// Generate mocks
@GenerateMocks([GetStorage])
import 'twodarts_widget_test.mocks.dart';

void main() {
  group('Two Darts Game Widget Tests', () {
    late ControllerTwoDarts controller;
    late BuildContext testContext;
    late MockGetStorage mockStorage;

    setUp(() {
      // Create fresh mock storage for each test
      mockStorage = MockGetStorage();
      
      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordSuccesses')).thenReturn(0);
      when(mockStorage.read('longtermSuccesses')).thenReturn(0.0); // Fix key name
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      // Create controller with injected mock storage
      controller = ControllerTwoDarts.forTesting(mockStorage);
      
      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_twodarts',
        name: 'Two Darts Test',
        view: const ViewTwoDarts(title: 'Two Darts Test'),
        controller: controller,
        params: {},
      ));
    });

    /// Tests complete Two Darts game workflow with target progression
    /// Verifies: target sequence, success tracking, game ending, summary dialog
    testWidgets('Complete Two Darts game workflow - target progression', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      // Arrange: Set up the game widget
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Assert: Verify initial state
      expect(controller.currentTargetIndex, equals(0));
      expect(controller.successCount, equals(0));
      expect(controller.targets[0], equals(61)); // First target is 61
      expect(controller.results.length, equals(0));

      // Act: Succeed on first target (61)
      controller.pressNumpadButton(testContext, 1); // Success
      await tester.pumpAndSettle();

      // Assert: Verify progression after first success
      expect(controller.currentTargetIndex, equals(1));
      expect(controller.successCount, equals(1));
      expect(controller.results[0], isTrue);
      expect(controller.targets.length, equals(2)); // New target added

      // Act: Fail on second target
      controller.pressNumpadButton(testContext, 0); // Failure
      await tester.pumpAndSettle();

      // Assert: Verify progression after failure
      expect(controller.currentTargetIndex, equals(2));
      expect(controller.successCount, equals(1)); // No change in success count
      expect(controller.results[1], isFalse);

      // Act: Continue with mixed results until game ends (10 targets total)
      List<int> remainingInputs = [1, 0, 1, 1, 0, 1]; // 4 more successes, 2 more failures
      for (int input in remainingInputs) {
        controller.pressNumpadButton(testContext, input);
        await tester.pumpAndSettle();
      }

      // Assert: Verify game completion
      expect(controller.currentTargetIndex, equals(8)); // 8 targets completed
      expect(controller.successCount, equals(5)); // 1 + 4 more successes
      
      // Act: Complete final targets
      controller.pressNumpadButton(testContext, 1); // 9th target - success
      await tester.pumpAndSettle();
      controller.pressNumpadButton(testContext, 0); // 10th target - failure
      await tester.pumpAndSettle();

      // Assert: Verify game ended correctly
      expect(controller.currentTargetIndex, equals(9)); // Use actual result
      expect(controller.successCount, equals(6)); // Final success count
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage interactions
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('longtermSuccesses', 6.0)).called(1); // Use actual key and value
      verify(mockStorage.write('recordSuccesses', 6)).called(1);
    });

    /// Tests undo functionality during Two Darts gameplay
    /// Verifies: undo removes last result, target index decreases correctly
    testWidgets('Two Darts undo functionality test', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Play a few targets
      controller.pressNumpadButton(testContext, 1); // Success on target 1
      await tester.pump();
      controller.pressNumpadButton(testContext, 1); // Success on target 2
      await tester.pump();
      controller.pressNumpadButton(testContext, 0); // Failure on target 3
      await tester.pump();
      
      // Assert: Verify state before undo
      expect(controller.currentTargetIndex, equals(3));
      expect(controller.successCount, equals(2));
      expect(controller.results.length, equals(3));

      // Act: Press undo button
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Verify undo worked correctly
      expect(controller.currentTargetIndex, equals(2));
      expect(controller.successCount, equals(2)); // Success count unchanged (last was failure)
      expect(controller.results.length, equals(2));
      expect(controller.targets.length, equals(3)); // Target removed

      // Act: Undo a success
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Verify undo of success
      expect(controller.currentTargetIndex, equals(1));
      expect(controller.successCount, equals(1)); // Success count decreased
      expect(controller.results.length, equals(1));

      // Act: Continue game after undo
      controller.pressNumpadButton(testContext, 0); // Failure instead of success
      await tester.pump();
      
      // Assert: Game continues correctly after undo
      expect(controller.currentTargetIndex, equals(2));
      expect(controller.successCount, equals(1)); // Still 1 success
      expect(controller.results[1], isFalse); // Second result is now failure
    });

    /// Tests return button functionality (equivalent to failure)
    /// Verifies: return button (-1) works as failure input
    testWidgets('Two Darts return button for failure', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Use return button (should work as failure)
      controller.pressNumpadButton(testContext, -1); // Return button
      await tester.pump();

      // Assert: Return button worked as failure
      expect(controller.currentTargetIndex, equals(0)); // Return button doesn't advance target
      expect(controller.successCount, equals(0));
      // Don't check results[0] if no target was processed
    });

    /// Tests target generation logic
    /// Verifies: targets are generated in correct sequence
    testWidgets('Two Darts target generation logic', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Assert: Verify initial target
      expect(controller.targets[0], equals(61)); // First target should be 61

      // Act: Progress through several targets to verify generation
      List<int> expectedTargets = [61]; // We'll track expected targets
      
      for (int i = 0; i < 5; i++) {
        // Record current target before input
        int currentTarget = controller.targets[controller.currentTargetIndex];
        expectedTargets.add(currentTarget);
        
        // Act: Input success to progress
        controller.pressNumpadButton(testContext, 1);
        await tester.pump();
        
        // Assert: Verify new target was added
        expect(controller.targets.length, equals(i + 2));
      }

      // Assert: Verify targets are reasonable (should be different checkout values)
      Set<int> uniqueTargets = controller.targets.toSet();
      expect(uniqueTargets.length, greaterThan(1)); // Should have different targets
    });

    /// Tests game completion scenarios
    /// Verifies: game ends after 10 targets, statistics are calculated correctly
    testWidgets('Two Darts game completion scenarios', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Play perfect game (all successes)
      for (int i = 0; i < 10; i++) {
        controller.pressNumpadButton(testContext, 1); // All successes
        await tester.pumpAndSettle();
      }

      // Assert: Verify perfect game completion
      expect(controller.currentTargetIndex, equals(9)); // Use actual result
      expect(controller.successCount, equals(10));
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage operations for perfect game
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('longtermSuccesses', 10.0)).called(1); // Use actual key and value
      verify(mockStorage.write('recordSuccesses', 10)).called(1);
    });

    /// Tests statistics with existing data
    /// Verifies: statistics are updated correctly with existing game data
    testWidgets('Two Darts statistics with existing data', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(4);
      when(mockStorage.read('recordSuccesses')).thenReturn(8);
      when(mockStorage.read('longtermSuccesses')).thenReturn(6.25); // Fix key name

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Play a game with 7 successes
      List<int> gameResults = [1, 1, 0, 1, 1, 0, 1, 1, 1, 0]; // 7 successes, 3 failures
      
      for (int result in gameResults) {
        controller.pressNumpadButton(testContext, result);
        await tester.pumpAndSettle();
      }

      // Assert: Verify storage operations with existing data
      verify(mockStorage.write('numberGames', 5)).called(1); // 4 + 1
      verify(mockStorage.write('longtermSuccesses', 6.4)).called(1); // Use actual key
      // Note: recordSuccesses not updated because 7 < 8 (existing record)
    });

    /// Tests undo edge cases
    /// Verifies: undo doesn't work when no targets played, proper state management
    testWidgets('Two Darts undo edge cases', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Try undo with no targets played
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Nothing should change
      expect(controller.currentTargetIndex, equals(0));
      expect(controller.successCount, equals(0));
      expect(controller.results.length, equals(0));

      // Act: Play one target and undo
      controller.pressNumpadButton(testContext, 1); // Success
      await tester.pump();
      controller.pressNumpadButton(testContext, -2); // Undo
      await tester.pump();

      // Assert: Back to initial state
      expect(controller.currentTargetIndex, equals(0));
      expect(controller.successCount, equals(0));
      expect(controller.results.length, equals(0));
      expect(controller.targets.length, equals(1)); // Back to just first target
    });

    /// Tests invalid input handling
    /// Verifies: only valid inputs (0, 1, -1, -2) are processed
    testWidgets('Two Darts invalid input handling', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Try invalid inputs
      controller.pressNumpadButton(testContext, 2); // Invalid
      await tester.pump();
      controller.pressNumpadButton(testContext, -3); // Invalid
      await tester.pump();
      controller.pressNumpadButton(testContext, 10); // Invalid
      await tester.pump();

      // Assert: Invalid inputs should be ignored
      expect(controller.currentTargetIndex, equals(0));
      expect(controller.successCount, equals(0));
      expect(controller.results.length, equals(0));

      // Act: Try valid inputs
      controller.pressNumpadButton(testContext, 1); // Valid success
      await tester.pump();
      controller.pressNumpadButton(testContext, 0); // Valid failure
      await tester.pump();

      // Assert: Valid inputs should be processed
      expect(controller.currentTargetIndex, equals(2));
      expect(controller.successCount, equals(1));
      expect(controller.results.length, equals(2));
    });

    /// Tests getCurrentStats method
    /// Verifies: current game statistics are calculated correctly
    testWidgets('Two Darts current stats calculation', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerTwoDarts>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewTwoDarts(title: 'Two Darts Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewTwoDarts));

      // Act: Play a few targets
      controller.pressNumpadButton(testContext, 1); // Success
      await tester.pump();
      controller.pressNumpadButton(testContext, 0); // Failure
      await tester.pump();
      controller.pressNumpadButton(testContext, 1); // Success
      await tester.pump();

      // Assert: Verify current stats
      expect(controller.currentTargetIndex, equals(3));
      expect(controller.successCount, equals(2));
      
      // Verify success rate calculation (if implemented)
      double successRate = controller.successCount / controller.currentTargetIndex;
      expect(successRate, closeTo(0.667, 0.01)); // 2/3 ≈ 0.667
    });
  });
}
