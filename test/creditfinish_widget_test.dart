import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_creditfinish.dart';
import 'package:dart/view/view_creditfinish.dart';
import 'package:dart/widget/menu.dart';

import 'creditfinish_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('Credit Finish Game Widget Tests', () {
    late ControllerCreditFinish controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('bestAvgChecks')).thenReturn(0.0);
      when(mockStorage.read('longtermAvgChecks')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      // Create controller with injected mock storage
      controller = ControllerCreditFinish.forTesting(mockStorage);

      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_creditfinish',
        name: 'Credit Finish Test',
        view: const ViewCreditFinish(title: 'Credit Finish Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    /// Tests basic Credit Finish game initialization
    /// Verifies: initial state, phase setup
    testWidgets('Credit Finish game initialization', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Assert: Initial game state
      expect(controller.getCurrentPhase(), equals(GamePhase.scoreInput));
      expect(controller.getInput(), equals(""));
      expect(controller.getScores().length, equals(0));
      expect(controller.getFinishResults().length, equals(0));
      expect(controller.getMissCount(), equals(0));
      expect(controller.gameEnded, equals(false));
    });

    /// Tests score input validation during typing
    /// Verifies: input validation prevents invalid scores like xxxcheckout
    testWidgets('Credit Finish input validation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Act: Try to enter "200" (should stop at "18")
      controller.pressNumpadButton(2);
      await tester.pump();
      controller.pressNumpadButton(0);
      await tester.pump();
      controller.pressNumpadButton(0);
      await tester.pump();

      // Assert: Input should be "20" not "200"
      expect(controller.getInput(), equals("20"));

      // Act: Try to enter "181" (should stop at "18")
      controller.pressNumpadButton(-2); // Clear
      await tester.pump();
      controller.pressNumpadButton(1);
      await tester.pump();
      controller.pressNumpadButton(8);
      await tester.pump();
      controller.pressNumpadButton(1);
      await tester.pump();

      // Assert: Input should be "18" not "181"
      expect(controller.getInput(), equals("18"));
    });

    /// Tests credit calculation system
    /// Verifies: correct credit assignment based on score ranges
    testWidgets('Credit Finish credit calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Test 1: Score < 57 = 0 credits (auto-miss)
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(6);
      controller.pressNumpadButton(-1); // Enter
      await tester.pump();

      expect(controller.getScores().last, equals(56));
      expect(controller.getCredits().last, equals(0));
      expect(controller.getFinishResults().last, equals(false)); // Auto-miss
      expect(controller.getMissCount(), equals(1));
      expect(controller.getCurrentPhase(), equals(GamePhase.scoreInput)); // Back to input

      // Test 2: Score 57-94 = 1 credit
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter
      await tester.pump();

      expect(controller.getScores().last, equals(80));
      expect(controller.getCredits().last, equals(1));
      expect(controller.getCurrentPhase(), equals(GamePhase.finishInput)); // Waiting for finish

      // Choose success
      controller.pressNumpadButton(1); // Yes
      await tester.pump();

      expect(controller.getFinishResults().last, equals(true));
      expect(controller.getMissCount(), equals(1)); // Still 1
      expect(controller.getCurrentPhase(), equals(GamePhase.scoreInput));

      // Test 3: Score 95-132 = 2 credits
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter
      await tester.pump();

      expect(controller.getScores().last, equals(100));
      expect(controller.getCredits().last, equals(2));
      expect(controller.getCurrentPhase(), equals(GamePhase.finishInput));

      // Choose miss
      controller.pressNumpadButton(0); // No
      await tester.pump();

      expect(controller.getFinishResults().last, equals(false));
      expect(controller.getMissCount(), equals(2));

      // Test 4: Score 133+ = 3 credits
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter
      await tester.pump();

      expect(controller.getScores().last, equals(150));
      expect(controller.getCredits().last, equals(3));
    });

    /// Tests undo functionality
    /// Verifies: undo clears input first, then removes complete rounds
    testWidgets('Credit Finish undo functionality', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Act: Enter partial input
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(2);
      await tester.pump();

      expect(controller.getInput(), equals("12"));

      // Act: Undo clears input first
      controller.pressNumpadButton(-2);
      await tester.pump();

      expect(controller.getInput(), equals(""));
      expect(controller.getScores().length, equals(0));

      // Act: Complete a round
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter 100
      await tester.pump();
      controller.pressNumpadButton(1); // Yes
      await tester.pump();

      expect(controller.getScores().length, equals(1));
      expect(controller.getFinishResults().length, equals(1));

      // Act: Undo removes complete round
      controller.pressNumpadButton(-2);
      await tester.pump();

      expect(controller.getScores().length, equals(0));
      expect(controller.getFinishResults().length, equals(0));
    });

    /// Tests game end condition
    /// Verifies: game ends after 10 misses
    testWidgets('Credit Finish game end condition', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Act: Create 9 misses (auto-miss with scores < 57)
      for (int i = 0; i < 9; i++) {
        controller.pressNumpadButton(5);
        controller.pressNumpadButton(0);
        controller.pressNumpadButton(-1); // Enter 50
        await tester.pump();
      }

      expect(controller.getMissCount(), equals(9));
      expect(controller.gameEnded, equals(false));

      // Act: 10th miss should end game
      controller.pressNumpadButton(4);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter 40
      await tester.pump();

      expect(controller.getMissCount(), equals(10));
      expect(controller.gameEnded, equals(true));
    });

    /// Tests statistics calculation
    /// Verifies: correct percentage calculation for checks
    testWidgets('Credit Finish statistics calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Test 1: Initial state
      Map stats = controller.getCurrentStats();
      expect(stats['rounds'], equals(0));
      expect(stats['checks'], equals(0));
      expect(stats['misses'], equals(0));

      // Test 2: After 1 success and 1 miss
      // Success
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter 100
      await tester.pump();
      controller.pressNumpadButton(1); // Yes
      await tester.pump();

      // Miss (auto-miss)
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter 50
      await tester.pump();

      stats = controller.getCurrentStats();
      expect(stats['rounds'], equals(2));
      expect(stats['checks'], equals(1));
      expect(stats['misses'], equals(1));

      // Test 3: After manual miss
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Enter 80
      await tester.pump();
      controller.pressNumpadButton(0); // No
      await tester.pump();

      stats = controller.getCurrentStats();
      expect(stats['rounds'], equals(3));
      expect(stats['checks'], equals(1));
      expect(stats['misses'], equals(2));
    });

    /// Tests table scrolling behavior
    /// Verifies: table shows last 5 rounds like xxxcheckout
    testWidgets('Credit Finish table scrolling', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCreditFinish>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCreditFinish(title: 'Credit Finish Test'),
          ),
        ),
      );

      // Act: Play 7 rounds (more than 5)
      for (int i = 0; i < 7; i++) {
        controller.pressNumpadButton(1);
        controller.pressNumpadButton(0);
        controller.pressNumpadButton(0);
        controller.pressNumpadButton(-1); // Enter 100
        await tester.pump();
        controller.pressNumpadButton(1); // Yes
        await tester.pump();
      }

      // Assert: Should show last 5 rounds (3-7)
      String rounds = controller.getCurrentRounds();
      String scores = controller.getCurrentScores();
      String credits = controller.getCurrentCredits();
      String results = controller.getCurrentResults();

      // Should contain rounds 3,4,5,6,7 (last 5)
      expect(rounds.split('\n').length, equals(5));
      expect(rounds, contains('3'));
      expect(rounds, contains('7'));
      expect(rounds, isNot(contains('1')));
      expect(rounds, isNot(contains('2')));

      expect(scores.split('\n').length, equals(5));
      expect(credits.split('\n').length, equals(5));
      expect(results.split('\n').length, equals(5));
      
      // Credits should show "2" for each 100-point score
      expect(credits, contains('2'));
    });
  });
}
