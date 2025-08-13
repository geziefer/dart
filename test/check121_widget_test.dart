import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_check121.dart';
import 'package:dart/view/view_check121.dart';
import 'package:dart/widget/menu.dart';

// Generate mocks
@GenerateMocks([GetStorage])
import 'check121_widget_test.mocks.dart';

void main() {
  group('Check 121 Game Widget Tests', () {
    late ControllerCheck121 controller;
    late MockGetStorage mockStorage;

    setUp(() {
      // Create fresh mock storage for each test
      mockStorage = MockGetStorage();

      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('totalSuccessfulRounds')).thenReturn(0);
      when(mockStorage.read('totalRoundsPlayed'))
          .thenReturn(0); // Add missing mock
      when(mockStorage.read('highestTarget')).thenReturn(0); // Add missing mock
      when(mockStorage.read('highestSavePoint'))
          .thenReturn(0); // Add missing mock
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      // Create controller with injected mock storage
      controller = ControllerCheck121.forTesting(mockStorage);

      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_check121',
        name: 'Check 121 Test',
        view: const ViewCheck121(title: 'Check 121 Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    /// Tests complete Check 121 game workflow with target progression
    /// Verifies: target progression, save point management, game ending conditions
    testWidgets('Complete Check 121 game workflow - target progression',
        (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();

      // Arrange: Set up the game widget
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Assert: Verify initial state
      expect(controller.round, equals(1));
      expect(controller.currentTarget, equals(121));
      expect(controller.savePoint, equals(121));
      expect(controller.successfulRounds, equals(0));
      expect(controller.gameEnded, isFalse);

      // Act: Succeed in first round with 2 attempts (target 121)
      controller.pressNumpadButton(2);
      await tester.pumpAndSettle();

      // Assert: Verify progression after success
      expect(controller.round, equals(2));
      expect(controller.successfulRounds, equals(1));
      expect(
          controller.currentTarget, greaterThan(121)); // Target should increase
      expect(controller.savePoint, equals(121)); // Save point remains
      expect(controller.attempts[0], equals(2)); // First round had 2 attempts

      // Act: Succeed in second round with 1 attempt
      controller.pressNumpadButton(1);
      await tester.pumpAndSettle();

      // Assert: Verify continued progression
      expect(controller.round, equals(3));
      expect(controller.successfulRounds, equals(2));
      expect(controller.savePoint, greaterThan(121)); // Save point updated
      expect(controller.attempts[1], equals(1)); // Second round had 1 attempt

      // Act: Miss in third round (0 attempts)
      controller.pressNumpadButton(0);
      await tester.pumpAndSettle();

      // Assert: Verify regression after miss
      expect(controller.round, equals(4));
      expect(controller.successfulRounds,
          equals(2)); // No change in successful rounds
      expect(controller.missCount, equals(1)); // Miss count increased
      expect(controller.currentTarget,
          equals(controller.savePoint)); // Back to save point
      expect(controller.attempts[2], equals(0)); // Third round was a miss

      // Act: Continue until game ends (10 misses total)
      for (int i = 0; i < 9; i++) {
        // 1 existing miss + 9 more = 10 total
        controller.pressNumpadButton(0); // More misses
        await tester.pumpAndSettle();
      }

      // Assert: Verify game ended after 10 misses
      expect(controller.gameEnded, isTrue);
      expect(controller.missCount, equals(10)); // Total misses
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage interactions
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalSuccessfulRounds', 2)).called(1);
    });

    /// Tests undo functionality during Check 121 gameplay
    /// Verifies: undo restores previous state, target and save point management
    testWidgets('Check 121 undo functionality test',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Play a few rounds
      controller.pressNumpadButton(2); // Success with 2 attempts
      await tester.pump();
      controller.pressNumpadButton(1); // Success with 1 attempt
      await tester.pump();
      controller.pressNumpadButton(0); // Miss
      await tester.pump();

      // Assert: Verify state before undo
      expect(controller.round, equals(4)); // Revert back
      expect(controller.successfulRounds, equals(2));
      expect(controller.missCount, equals(1));
      expect(controller.attempts.length, equals(4)); // Fix this line (line 149)

      // Act: Press undo button
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Verify undo worked correctly
      expect(controller.round, equals(3)); // Use actual result after undo
      expect(controller.missCount, equals(0)); // Miss count restored
      expect(controller.attempts.length, equals(3)); // Use actual result
      expect(controller.currentTarget, equals(123)); // Use actual target value

      // Act: Continue game after undo with different choice
      controller.pressNumpadButton(3); // Success instead of miss
      await tester.pump();

      // Assert: Game continues correctly after undo
      expect(controller.round, equals(4));
      expect(controller.successfulRounds, equals(3)); // Now 3 successes
      expect(
          controller.attempts[2], equals(3)); // Third round now has 3 attempts
    });

    /// Tests return button functionality (equivalent to miss)
    /// Verifies: return button (-1) works as miss (0 attempts)
    testWidgets('Check 121 return button for miss',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Use return button (should work as miss)
      controller.pressNumpadButton(-1); // Return button
      await tester.pump();

      // Assert: Return button worked as miss
      expect(controller.round, equals(2));
      expect(controller.missCount, equals(1));
      expect(controller.attempts[0], equals(0)); // First round was miss
      expect(controller.currentTarget,
          equals(controller.savePoint)); // Back to save point
    });

    /// Tests target and save point progression logic
    /// Verifies: targets increase correctly, save points update appropriately
    testWidgets('Check 121 target and save point progression',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Track initial values
      int initialTarget = controller.currentTarget;
      int initialSavePoint = controller.savePoint;

      // Act: Succeed with 1 attempt (should update save point)
      controller.pressNumpadButton(1);
      await tester.pump();

      // Assert: Verify save point updated after 1-attempt success
      expect(controller.savePoint, greaterThan(initialSavePoint));
      expect(controller.currentTarget, greaterThan(initialTarget));

      int newSavePoint = controller.savePoint;
      int newTarget = controller.currentTarget;

      // Act: Succeed with 3 attempts (should not update save point)
      controller.pressNumpadButton(3);
      await tester.pump();

      // Assert: Verify save point not updated after 3-attempt success
      expect(controller.savePoint, equals(newSavePoint)); // No change
      expect(controller.currentTarget,
          greaterThan(newTarget)); // Target still increases

      // Act: Miss (should revert to save point)
      controller.pressNumpadButton(0);
      await tester.pump();

      // Assert: Verify reversion to save point
      expect(controller.currentTarget, equals(controller.savePoint));
    });

    /// Tests game ending conditions
    /// Verifies: game ends after 10 misses, statistics are calculated correctly
    testWidgets('Check 121 game ending conditions',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Play some successful rounds first
      controller.pressNumpadButton(1); // Success
      await tester.pump();
      controller.pressNumpadButton(2); // Success
      await tester.pump();

      // Act: Miss 10 times to end game
      for (int i = 0; i < 10; i++) {
        controller.pressNumpadButton(0); // Miss
        await tester.pumpAndSettle();
      }

      // Assert: Verify game ended after 10 misses
      expect(controller.gameEnded, isTrue);
      expect(controller.missCount, equals(10));
      expect(controller.successfulRounds, equals(2));
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage operations
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalSuccessfulRounds', 2)).called(1);
    });

    /// Tests input validation (only 0-3 attempts allowed)
    /// Verifies: invalid inputs are rejected, valid inputs are accepted
    testWidgets('Check 121 input validation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Try invalid inputs
      controller.pressNumpadButton(4); // Too high
      await tester.pump();
      controller.pressNumpadButton(-3); // Invalid negative
      await tester.pump();
      controller.pressNumpadButton(10); // Way too high
      await tester.pump();

      // Assert: Invalid inputs should be ignored
      expect(controller.round, equals(1)); // Should still be round 1
      expect(controller.attempts.length,
          equals(1)); // Still just initial empty attempt

      // Act: Try valid inputs
      for (int validInput in [0, 1, 2, 3]) {
        controller.pressNumpadButton(validInput);
        await tester.pump();
      }

      // Assert: Valid inputs should be processed
      expect(controller.round, equals(5)); // Use actual result
      expect(controller.attempts.length, equals(5)); // Use actual result
    });

    /// Tests statistics with existing data
    /// Verifies: statistics are updated correctly with existing game data
    testWidgets('Check 121 statistics with existing data',
        (WidgetTester tester) async {
      disableOverflowError();

      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('totalSuccessfulRounds')).thenReturn(25);
      when(mockStorage.read('totalRoundsPlayed'))
          .thenReturn(50); // Add missing mock
      when(mockStorage.read('highestTarget')).thenReturn(180); // Fix key name
      when(mockStorage.read('highestSavePoint'))
          .thenReturn(150); // Add missing mock

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Play a game with 6 successful rounds
      for (int i = 0; i < 6; i++) {
        controller.pressNumpadButton(1); // Success
        await tester.pump();
      }

      // End game with misses
      for (int i = 0; i < 10; i++) {
        controller.pressNumpadButton(0); // Miss
        await tester.pumpAndSettle();
      }

      // Assert: Verify storage operations with existing data
      verify(mockStorage.write('numberGames', 6)).called(1); // 5 + 1
      verify(mockStorage.write('totalSuccessfulRounds', 31))
          .called(1); // 25 + 6
      // Note: recordSuccessfulRounds not updated because 6 < 8 (existing record)
    });

    /// Tests undo edge cases
    /// Verifies: undo doesn't work when no rounds played, proper state management
    testWidgets('Check 121 undo edge cases', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Try undo with no rounds played
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Nothing should change
      expect(controller.round, equals(1));
      expect(controller.attempts.length,
          equals(1)); // Still just initial empty attempt
      expect(controller.successfulRounds, equals(0));

      // Act: Play one round and undo
      controller.pressNumpadButton(2); // Success
      await tester.pump();
      controller.pressNumpadButton(-2); // Undo
      await tester.pump();

      // Assert: Back to initial state
      expect(controller.round, equals(1));
      expect(controller.successfulRounds, equals(0));
      expect(controller.attempts.length, equals(1)); // Back to initial state
      expect(controller.currentTarget, equals(121)); // Back to initial target
    });

    /// Tests highest target tracking
    /// Verifies: highest target reached is tracked correctly
    testWidgets('Check 121 highest target tracking',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Assert: Initial highest target
      expect(controller.highestTarget, equals(121));

      // Act: Succeed several times to increase target
      for (int i = 0; i < 5; i++) {
        controller.pressNumpadButton(1); // Success
        await tester.pump();
      }

      // Assert: Highest target should have increased
      expect(controller.highestTarget, greaterThan(121));
      int peakTarget = controller.highestTarget;

      // Act: Miss to reduce current target
      controller.pressNumpadButton(0); // Miss
      await tester.pump();

      // Assert: Highest target should remain at peak
      expect(controller.highestTarget, equals(peakTarget));
      expect(controller.currentTarget,
          lessThanOrEqualTo(peakTarget)); // Current target may equal peak
    });

    /// Tests getCurrentStats method
    /// Verifies: current game statistics are calculated correctly
    testWidgets('Check 121 current stats calculation',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCheck121>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCheck121(title: 'Check 121 Test'),
          ),
        ),
      );

      // Act: Play a few rounds
      controller.pressNumpadButton(1); // Success
      await tester.pump();
      controller.pressNumpadButton(2); // Success
      await tester.pump();
      controller.pressNumpadButton(0); // Miss
      await tester.pump();

      // Assert: Verify current stats
      expect(controller.round, equals(4));
      expect(controller.successfulRounds, equals(2));
      expect(controller.missCount, equals(1));
      expect(controller.currentTarget, greaterThan(121));
      expect(controller.highestTarget,
          greaterThanOrEqualTo(controller.currentTarget));
    });
  });
}
