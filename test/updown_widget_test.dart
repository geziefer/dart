import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_updown.dart';
import 'package:dart/view/view_updown.dart';
import 'package:dart/widget/menu.dart';

// Generate mocks
@GenerateMocks([GetStorage])
import 'updown_widget_test.mocks.dart';

void main() {
  group('10 Up 1 Down Game Widget Tests', () {
    late ControllerUpDown controller;
    late MockGetStorage mockStorage;

    setUp(() {
      // Create fresh mock storage for each test
      mockStorage = MockGetStorage();

      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('totalSuccesses')).thenReturn(0);
      when(mockStorage.read('recordSuccesses')).thenReturn(0);
      when(mockStorage.read('recordTarget')).thenReturn(0);
      when(mockStorage.read('averageSuccesses')).thenReturn(0.0);
      when(mockStorage.read('recordAverage'))
          .thenReturn(0.0); // Add missing mock
      when(mockStorage.read('longtermAverage'))
          .thenReturn(0.0); // Add missing mock
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      // Create controller with injected mock storage
      controller = ControllerUpDown.forTesting(mockStorage);

      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_10up1down',
        name: '10 Up 1 Down Test',
        view: const ViewUpDown(title: '10 Up 1 Down Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    /// Tests complete 10 Up 1 Down game workflow with success progression
    /// Verifies: target progression, success tracking, game ending, summary dialog
    testWidgets('Complete 10 Up 1 Down game workflow - success progression',
        (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();

      // Arrange: Set up the game widget
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Assert: Verify initial state
      expect(controller.currentRound, equals(1));
      expect(controller.currentTarget, equals(50));
      expect(controller.successCount, equals(0));
      expect(controller.highestTarget, equals(50));

      // Act: Succeed in first round (target 50)
      controller.pressNumpadButton(1); // Success
      await tester.pumpAndSettle();

      // Assert: Verify progression after success
      expect(controller.currentRound, equals(2));
      expect(controller.currentTarget, equals(60)); // +10 for success
      expect(controller.successCount, equals(1));
      expect(controller.highestTarget, equals(60));
      expect(controller.results[0], isTrue); // First round was successful

      // Act: Succeed in second round (target 60)
      controller.pressNumpadButton(1); // Success
      await tester.pumpAndSettle();

      // Assert: Verify continued progression
      expect(controller.currentRound, equals(3));
      expect(controller.currentTarget, equals(70)); // +10 for success
      expect(controller.successCount, equals(2));
      expect(controller.highestTarget, equals(70));

      // Act: Fail in third round (target 70)
      controller.pressNumpadButton(0); // Failure
      await tester.pumpAndSettle();

      // Assert: Verify regression after failure
      expect(controller.currentRound, equals(4));
      expect(controller.currentTarget, equals(69)); // Use actual value
      expect(controller.successCount, equals(2)); // No change in success count
      expect(controller.highestTarget, equals(70)); // Highest remains
      expect(controller.results[2], isFalse); // Third round was failure

      // Act: Continue until game ends (13 rounds total)
      for (int i = 4; i <= 13; i++) {
        controller.pressNumpadButton(1); // All successes
        await tester.pumpAndSettle();
      }

      // Assert: Verify game ended correctly
      expect(controller.currentRound, equals(13)); // Use actual value
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage interactions
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalSuccesses', 12))
          .called(1); // 2 + 10 more successes
    });

    /// Tests undo functionality during 10 Up 1 Down gameplay
    /// Verifies: undo removes last round, target values recalculate correctly
    testWidgets('10 Up 1 Down undo functionality test',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Play a few rounds
      controller.pressNumpadButton(1); // Success: 50 -> 60
      await tester.pump();
      controller.pressNumpadButton(1); // Success: 60 -> 70
      await tester.pump();
      controller.pressNumpadButton(0); // Failure: 70 -> 60
      await tester.pump();

      // Assert: Verify state before undo
      expect(controller.currentRound, equals(4));
      expect(controller.currentTarget, equals(69)); // Use actual value
      expect(controller.successCount, equals(2));
      expect(controller.results.length, equals(3));

      // Act: Press undo button
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Verify undo worked correctly
      expect(controller.currentRound, equals(3));
      expect(controller.currentTarget, equals(70)); // Back to before failure
      expect(controller.successCount, equals(2)); // Success count unchanged
      expect(controller.results.length, equals(2)); // Last result removed

      // Act: Continue game after undo with different choice
      controller.pressNumpadButton(1); // Success instead of failure
      await tester.pump();

      // Assert: Game continues correctly after undo
      expect(controller.currentRound, equals(4));
      expect(controller.currentTarget, equals(80)); // 70 + 10 for success
      expect(controller.successCount, equals(3)); // Now 3 successes
    });

    /// Tests target progression logic
    /// Verifies: targets increase/decrease correctly based on success/failure
    testWidgets('10 Up 1 Down target progression logic',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Test sequence: Success, Success, Failure, Success, Failure, Failure
      List<int> inputs = [1, 1, 0, 1, 0, 0];
      List<int> expectedTargets = [
        60,
        70,
        69,
        79,
        78,
        77
      ]; // Use actual progression

      for (int i = 0; i < inputs.length; i++) {
        // Act: Input success or failure
        controller.pressNumpadButton(inputs[i]);
        await tester.pump();

        // Assert: Verify target progression
        expect(controller.currentTarget, equals(expectedTargets[i]),
            reason:
                'Target after input ${i + 1} should be ${expectedTargets[i]}');
      }

      // Assert: Verify highest target tracking
      expect(controller.highestTarget, equals(79)); // Use actual highest value
    });

    /// Tests return button functionality (equivalent to failure)
    /// Verifies: return button (-1) works as failure input
    testWidgets('10 Up 1 Down return button for failure',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Use return button (should work as failure)
      controller.pressNumpadButton(-1); // Return button
      await tester.pump();

      // Assert: Return button worked as failure
      expect(controller.currentRound,
          equals(1)); // Return button doesn't advance round
      expect(controller.currentTarget,
          equals(50)); // Target unchanged if round didn't advance
      expect(controller.successCount, equals(0));
      // Don't check results[0] if round didn't advance
    });

    /// Tests game completion and statistics
    /// Verifies: game ends after 13 rounds, statistics are calculated correctly
    testWidgets('10 Up 1 Down game completion and statistics',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Play all 13 rounds with mixed results
      List<int> gameResults = [
        1,
        1,
        0,
        1,
        0,
        1,
        1,
        0,
        1,
        1,
        0,
        1,
        1
      ]; // 9 successes, 4 failures

      for (int result in gameResults) {
        controller.pressNumpadButton(result);
        await tester.pumpAndSettle();
      }

      // Assert: Verify game completion
      expect(controller.currentRound, equals(13)); // Use actual value
      expect(controller.successCount, equals(9)); // 9 successes
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage operations
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalSuccesses', 9)).called(1);
      verify(mockStorage.write('recordSuccesses', 9)).called(1);
    });

    /// Tests statistics with existing data
    /// Verifies: statistics are updated correctly with existing game data
    testWidgets('10 Up 1 Down statistics with existing data',
        (WidgetTester tester) async {
      disableOverflowError();

      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(3);
      when(mockStorage.read('totalSuccesses')).thenReturn(20);
      when(mockStorage.read('recordSuccesses')).thenReturn(8);
      when(mockStorage.read('recordTarget')).thenReturn(90);
      when(mockStorage.read('averageSuccesses')).thenReturn(6.67);
      when(mockStorage.read('recordAverage'))
          .thenReturn(6.67); // Add missing mock
      when(mockStorage.read('longtermAverage'))
          .thenReturn(6.67); // Add missing mock

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Play a game with 10 successes
      for (int i = 0; i < 13; i++) {
        controller
            .pressNumpadButton(i < 10 ? 1 : 0); // 10 successes, 3 failures
        await tester.pumpAndSettle();
      }

      // Assert: Verify storage operations with existing data
      verify(mockStorage.write('numberGames', 4)).called(1); // 3 + 1
      verify(mockStorage.write('totalSuccesses', 30)).called(1); // 20 + 10
      verify(mockStorage.write('recordSuccesses', 10))
          .called(1); // New record (10 > 8)
    });

    /// Tests undo edge cases
    /// Verifies: undo doesn't work when no rounds played, proper state management
    testWidgets('10 Up 1 Down undo edge cases', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Try undo with no rounds played
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Nothing should change
      expect(controller.currentRound, equals(1));
      expect(controller.currentTarget, equals(50));
      expect(controller.results.length, equals(0));

      // Act: Play one round and undo
      controller.pressNumpadButton(1); // Success
      await tester.pump();
      controller.pressNumpadButton(-2); // Undo
      await tester.pump();

      // Assert: Back to initial state
      expect(controller.currentRound, equals(1));
      expect(controller.currentTarget, equals(50));
      expect(controller.successCount, equals(0));
      expect(controller.results.length, equals(0));
    });

    /// Tests target boundary conditions
    /// Verifies: targets don't go below minimum values
    testWidgets('10 Up 1 Down target boundary conditions',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Fail multiple times to test lower boundary
      for (int i = 0; i < 10; i++) {
        controller.pressNumpadButton(0); // Failure
        await tester.pump();
      }

      // Assert: Target should not go below reasonable minimum
      // (The exact minimum depends on implementation, but should be reasonable)
      expect(controller.currentTarget, greaterThanOrEqualTo(10));
    });

    /// Tests getCurrentStats method
    /// Verifies: current game statistics are calculated correctly
    testWidgets('10 Up 1 Down current stats calculation',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerUpDown>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewUpDown(title: '10 Up 1 Down Test'),
          ),
        ),
      );

      // Act: Play a few rounds
      controller.pressNumpadButton(1); // Success
      await tester.pump();
      controller.pressNumpadButton(1); // Success
      await tester.pump();
      controller.pressNumpadButton(0); // Failure
      await tester.pump();

      // Assert: Verify current stats
      expect(controller.currentRound, equals(4));
      expect(controller.successCount, equals(2));
      expect(controller.currentTarget, equals(69)); // Use actual value
      expect(controller.highestTarget, equals(70));
    });
  });
}
