import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/view/view_rtcx.dart';
import 'package:dart/widget/menu.dart';

import 'rtcx_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('RTCX Game Widget Tests', () {
    late ControllerRTCX controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();
      
      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('numberFinishes')).thenReturn(0);
      when(mockStorage.read('recordDarts')).thenReturn(0);
      when(mockStorage.read('longtermChecks')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      // Create controller with injected mock storage
      controller = ControllerRTCX.forTesting(mockStorage);
      
      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_rtcx',
        name: 'RTCX Test',
        view: const ViewRTCX(title: 'RTCX Test'),
        controller: controller,
        params: {'max': -1}, // Unlimited rounds
      ));
    });

    /// Tests complete RTCX game workflow - hitting numbers 1-20 in sequence
    /// Verifies: number progression, dart counting, game completion
    testWidgets('Complete RTCX game workflow - number progression', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Assert: Verify initial state
      expect(controller.currentNumber, equals(1));
      expect(controller.round, equals(1));
      expect(controller.dart, equals(0));
      expect(controller.finished, isFalse);

      // Act: Hit numbers 1-5 in sequence (each hit advances by 1)
      for (int i = 1; i <= 5; i++) {
        controller.pressNumpadButton(1); // Hit current number
        await tester.pump();
        
        expect(controller.currentNumber, equals(i + 1));
        expect(controller.round, equals(i + 1));
        expect(controller.dart, equals(i * 3)); // 3 darts per round
      }

      // Assert: Verify mid-game state
      expect(controller.currentNumber, equals(6));
      expect(controller.dart, equals(15));
      expect(controller.finished, isFalse);
    });

    /// Tests RTCX undo functionality
    /// Verifies: undo removes last throw, decreases round and dart count
    testWidgets('RTCX undo functionality test', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Act: Play a few rounds
      controller.pressNumpadButton(2); // Hit 1 and 2
      await tester.pump();
      controller.pressNumpadButton(1); // Hit 3
      await tester.pump();

      // Assert: Verify state before undo
      expect(controller.currentNumber, equals(4));
      expect(controller.round, equals(3));
      expect(controller.dart, equals(6));
      expect(controller.throws.length, equals(2));

      // Act: Undo last throw
      controller.pressNumpadButton(-2); // Undo button
      await tester.pump();

      // Assert: Verify undo worked
      expect(controller.currentNumber, equals(3));
      expect(controller.round, equals(2));
      expect(controller.dart, equals(3));
      expect(controller.throws.length, equals(1));
    });

    /// Tests RTCX return button functionality (equivalent to 0 hits)
    /// Verifies: return button advances round without hitting numbers
    testWidgets('RTCX return button for no hits', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Act: Use return button (should work as 0 hits)
      controller.pressNumpadButton(-1); // Return button
      await tester.pump();

      // Assert: Return button worked as 0 hits
      expect(controller.currentNumber, equals(1)); // No progress
      expect(controller.round, equals(2)); // Round advanced
      expect(controller.dart, equals(3)); // Darts counted
      expect(controller.throws[0], equals(0)); // 0 hits recorded
    });

    /// Tests RTCX input validation and limits
    /// Verifies: numbers beyond remaining targets are ignored
    testWidgets('RTCX input validation and limits', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Act: Try to hit more numbers than remaining (should be ignored)
      controller.pressNumpadButton(25); // Too many hits
      await tester.pump();

      // Assert: Invalid input was ignored
      expect(controller.currentNumber, equals(1)); // No change
      expect(controller.round, equals(1)); // No change
      expect(controller.dart, equals(0)); // No change

      // Act: Hit valid number of targets
      controller.pressNumpadButton(3); // Valid hits
      await tester.pump();

      // Assert: Valid input was processed
      expect(controller.currentNumber, equals(4));
      expect(controller.round, equals(2));
      expect(controller.dart, equals(3));
    });

    /// Tests RTCX game completion scenarios
    /// Verifies: game logic works correctly when completing the game
    testWidgets('RTCX game completion logic', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Act: Play game step by step to near completion
      controller.pressNumpadButton(10); // Hit numbers 1-10
      await tester.pump();
      controller.pressNumpadButton(9); // Hit numbers 11-19
      await tester.pump();
      
      // Assert: Verify near completion state
      expect(controller.currentNumber, equals(20)); // At number 20
      expect(controller.finished, isFalse);
      expect(controller.dart, equals(6)); // 2 rounds * 3 darts each

      // Act: Complete the game by hitting the last number
      controller.pressNumpadButton(1); // Hit number 20
      await tester.pump();

      // Assert: Verify game completion state (without waiting for dialogs)
      expect(controller.currentNumber, equals(21)); // Beyond 20
      expect(controller.finished, isTrue);
      expect(controller.dart, equals(9)); // 3 rounds * 3 darts each
    });

    /// Tests RTCX statistics calculation
    /// Verifies: statistics are calculated correctly during gameplay
    testWidgets('RTCX statistics calculation', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('numberFinishes')).thenReturn(3);
      when(mockStorage.read('recordDarts')).thenReturn(45);
      when(mockStorage.read('longtermChecks')).thenReturn(2.5);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Act: Play some rounds and check current stats
      controller.pressNumpadButton(5); // Hit numbers 1-5
      await tester.pump();
      
      // Assert: Verify current stats calculation
      Map stats = controller.getCurrentStats();
      expect(stats['throw'], equals(2)); // Current round
      expect(stats['darts'], equals(3)); // Total darts
      expect(stats['avgChecks'], equals('0.6')); // 3 darts / 5 numbers = 0.6
      
      // Assert: Verify stats string format
      String statsString = controller.getStats();
      expect(statsString, contains('#S: 5')); // Number of games
      expect(statsString, contains('#G: 3')); // Number of finishes
      expect(statsString, contains('♛D: 45')); // Record darts
      expect(statsString, contains('ØC: 2.5')); // Average checks
    });

    /// Tests RTCX undo edge cases
    /// Verifies: undo doesn't work when no throws played, proper state management
    testWidgets('RTCX undo edge cases', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Test'),
          ),
        ),
      );


      // Act: Try to undo when no throws have been made
      controller.pressNumpadButton(-2); // Undo button
      await tester.pump();

      // Assert: Undo had no effect (no throws to undo)
      expect(controller.currentNumber, equals(1));
      expect(controller.round, equals(1));
      expect(controller.dart, equals(0));
      expect(controller.throws.isEmpty, isTrue);
    });

    /// Tests RTCX round limit functionality
    /// Verifies: game logic respects max round limits
    testWidgets('RTCX round limit functionality', (WidgetTester tester) async {
      disableOverflowError();

      // Arrange: Create controller with round limit
      controller.init(MenuItem(
        id: 'test_rtcx_limited',
        name: 'RTCX Limited Test',
        view: const ViewRTCX(title: 'RTCX Limited Test'),
        controller: controller,
        params: {'max': 3}, // Limit to 3 rounds
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerRTCX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewRTCX(title: 'RTCX Limited Test'),
          ),
        ),
      );


      // Act: Play exactly 3 rounds (without completing the game)
      controller.pressNumpadButton(1); // Round 1
      await tester.pump();
      controller.pressNumpadButton(1); // Round 2
      await tester.pump();
      
      // Assert: Verify state before final round
      expect(controller.round, equals(3));
      expect(controller.currentNumber, equals(3));
      expect(controller.finished, isFalse);
      
      // Act: Play final round
      controller.pressNumpadButton(1); // Round 3
      await tester.pump();

      // Assert: Game ended due to round limit (without waiting for dialogs)
      expect(controller.round, equals(3));
      expect(controller.currentNumber, equals(4)); // Only hit 3 numbers
      expect(controller.finished, isFalse); // Not completed, just limited
    });
  });
}
