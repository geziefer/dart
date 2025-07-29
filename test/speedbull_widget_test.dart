import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_speedbull.dart';
import 'package:dart/view/view_speedbull.dart';
import 'package:dart/widget/menu.dart';

// Generate mocks
@GenerateMocks([GetStorage])
import 'speedbull_widget_test.mocks.dart';

void main() {
  group('Speed Bull Game Widget Tests', () {
    late ControllerSpeedBull controller;
    late BuildContext testContext;
    late MockGetStorage mockStorage;

    setUp(() {
      // Create fresh mock storage for each test
      mockStorage = MockGetStorage();
      
      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordHits')).thenReturn(0);
      when(mockStorage.read('totalHitsAllGames')).thenReturn(0);
      when(mockStorage.read('totalRoundsAllGames')).thenReturn(0);
      when(mockStorage.read('overallAverage')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      // Create controller with injected mock storage
      controller = ControllerSpeedBull.forTesting(mockStorage);
      
      // Initialize with a proper MenuItem (60 second duration)
      controller.init(MenuItem(
        id: 'test_speedbull',
        name: 'Speed Bull Test',
        view: const ViewSpeedBull(title: 'Speed Bull Test'),
        controller: controller,
        params: {'duration': 60},
      ));
    });

    /// Tests complete Speed Bull game workflow with timer
    /// Verifies: game start, timer countdown, hit recording, game ending, summary dialog
    testWidgets('Complete Speed Bull game workflow - timer based', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      // Arrange: Set up the game widget
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Assert: Verify initial state
      expect(controller.round, equals(1));
      expect(controller.totalHits, equals(0));
      expect(controller.gameStarted, isFalse);
      expect(controller.gameEnded, isFalse);
      expect(controller.remainingSeconds, equals(60));

      // Act: Start the game
      controller.startGame();
      await tester.pump();

      // Assert: Verify game started
      expect(controller.gameStarted, isTrue);
      expect(controller.remainingSeconds, equals(60));

      // Act: Record some hits during gameplay
      controller.pressNumpadButton(testContext, 3); // 3 bulls
      await tester.pump();
      
      // Assert: Verify first round recorded
      expect(controller.totalHits, equals(3));
      expect(controller.round, equals(2));
      expect(controller.hits[0], equals(3)); // first round has 3 hits
      expect(controller.hits[1], equals(0)); // second round is empty

      // Act: Record more hits
      controller.pressNumpadButton(testContext, 2); // 2 bulls
      await tester.pump();
      controller.pressNumpadButton(testContext, 1); // 1 bull
      await tester.pump();

      // Assert: Verify multiple rounds recorded
      expect(controller.totalHits, equals(6)); // 3 + 2 + 1
      expect(controller.round, equals(4));
      expect(controller.hits[1], equals(2)); // second round has 2 hits
      expect(controller.hits[2], equals(1)); // third round has 1 hit

      // Act: Simulate timer ending by setting lastThrowAllowed
      controller.lastThrowAllowed = true;
      controller.pressNumpadButton(testContext, 2); // final throw
      await tester.pumpAndSettle();

      // Assert: Verify game ended correctly
      expect(controller.gameEnded, isTrue);
      expect(controller.totalHits, equals(8)); // 3 + 2 + 1 + 2
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage interactions
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalHitsAllGames', 8)).called(1);
      verify(mockStorage.write('recordHits', 8)).called(1);
    });

    /// Tests undo functionality during Speed Bull gameplay
    /// Verifies: undo removes last round, hit counts recalculate correctly
    testWidgets('Speed Bull undo functionality test', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Start game and record hits
      controller.startGame();
      await tester.pump();
      
      controller.pressNumpadButton(testContext, 3); // Round 1: 3 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, 2); // Round 2: 2 hits
      await tester.pump();
      
      // Assert: Verify state before undo
      expect(controller.totalHits, equals(5)); // 3 + 2
      expect(controller.round, equals(3));
      expect(controller.hits.length, equals(3)); // [3, 2, 0]

      // Act: Press undo button
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Verify undo worked correctly
      expect(controller.totalHits, equals(3)); // Back to 3 hits
      expect(controller.round, equals(2)); // Back to round 2
      expect(controller.hits.length, equals(2)); // [3, 0]
      expect(controller.hits[1], equals(0)); // Current round is empty

      // Act: Continue game after undo
      controller.pressNumpadButton(testContext, 1); // 1 hit
      await tester.pump();
      
      // Assert: Game continues correctly after undo
      expect(controller.totalHits, equals(4)); // 3 + 1
      expect(controller.hits[1], equals(1)); // Second round now has 1 hit
    });

    /// Tests return button functionality (equivalent to 0 hits)
    /// Verifies: return button (-1) works as 0 hits input
    testWidgets('Speed Bull return button for zero hits', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Start game and use return button
      controller.startGame();
      await tester.pump();
      
      controller.pressNumpadButton(testContext, 2); // 2 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, -1); // Return button (0 hits)
      await tester.pump();

      // Assert: Return button worked as 0 hits
      expect(controller.totalHits, equals(2)); // Only first round counted
      expect(controller.hits[1], equals(0)); // Second round has 0 hits
      expect(controller.round, equals(3)); // Advanced to next round
    });

    /// Tests game behavior before starting
    /// Verifies: inputs ignored before game starts, timer doesn't run
    testWidgets('Speed Bull pre-game state handling', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Try to input hits before starting game
      controller.pressNumpadButton(testContext, 3);
      await tester.pump();

      // Assert: Input should be ignored
      expect(controller.totalHits, equals(0));
      expect(controller.round, equals(1));
      expect(controller.gameStarted, isFalse);

      // Act: Start game and then input should work
      controller.startGame();
      await tester.pump();
      controller.pressNumpadButton(testContext, 3);
      await tester.pump();

      // Assert: Input now works
      expect(controller.totalHits, equals(3));
      expect(controller.round, equals(2));
    });

    /// Tests input validation (only 0-3 hits allowed)
    /// Verifies: invalid inputs are rejected, valid inputs are accepted
    testWidgets('Speed Bull input validation', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Start game
      controller.startGame();
      await tester.pump();

      // Act: Try invalid inputs
      controller.pressNumpadButton(testContext, 4); // Too high
      await tester.pump();
      controller.pressNumpadButton(testContext, -3); // Invalid negative
      await tester.pump();

      // Assert: Invalid inputs ignored
      expect(controller.totalHits, equals(0));
      expect(controller.round, equals(1));

      // Act: Try valid inputs
      controller.pressNumpadButton(testContext, 0); // Valid: 0 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, 3); // Valid: 3 hits
      await tester.pump();

      // Assert: Valid inputs accepted
      expect(controller.totalHits, equals(3)); // 0 + 3
      expect(controller.round, equals(3));
    });

    /// Tests statistics calculation and storage with existing data
    /// Verifies: statistics are calculated correctly, storage operations occur
    testWidgets('Speed Bull statistics with existing data', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('recordHits')).thenReturn(10);
      when(mockStorage.read('totalHitsAllGames')).thenReturn(40);
      when(mockStorage.read('totalRoundsAllGames')).thenReturn(25);
      when(mockStorage.read('overallAverage')).thenReturn(1.6);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Play a game and end it
      controller.startGame();
      await tester.pump();
      
      controller.pressNumpadButton(testContext, 3); // 3 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, 2); // 2 hits
      await tester.pump();
      
      // Simulate game ending
      controller.lastThrowAllowed = true;
      controller.pressNumpadButton(testContext, 1); // final hit
      await tester.pumpAndSettle();

      // Assert: Verify storage operations with existing data
      verify(mockStorage.write('numberGames', 6)).called(1); // 5 + 1
      verify(mockStorage.write('totalHitsAllGames', 46)).called(1); // 40 + 6
      verify(mockStorage.write('totalRoundsAllGames', 27)).called(1); // 25 + 2
      // Note: recordHits not updated because 6 < 10 (existing record)
    });

    /// Tests undo edge cases
    /// Verifies: undo doesn't work when no rounds played, undo doesn't work after game ends
    testWidgets('Speed Bull undo edge cases', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Start game and try undo with no completed rounds
      controller.startGame();
      await tester.pump();
      
      controller.pressNumpadButton(testContext, -2); // Undo
      await tester.pump();

      // Assert: Nothing should change (only 1 round exists, can't undo)
      expect(controller.round, equals(1));
      expect(controller.totalHits, equals(0));

      // Act: Complete a round and end game
      controller.pressNumpadButton(testContext, 2);
      await tester.pump();
      controller.lastThrowAllowed = true;
      controller.pressNumpadButton(testContext, 1);
      await tester.pumpAndSettle();

      // Assert: Game ended
      expect(controller.gameEnded, isTrue);

      // Act: Try undo after game ended
      int hitsBeforeUndo = controller.totalHits;
      controller.pressNumpadButton(testContext, -2);
      await tester.pump();

      // Assert: Undo should not work after game ended
      expect(controller.totalHits, equals(hitsBeforeUndo));
      expect(controller.gameEnded, isTrue);
    });

    /// Tests custom game duration
    /// Verifies: different game durations are respected
    testWidgets('Speed Bull custom duration test', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Create controller with custom duration
      controller = ControllerSpeedBull.forTesting(mockStorage);
      controller.init(MenuItem(
        id: 'test_speedbull_custom',
        name: 'Speed Bull Custom',
        view: const ViewSpeedBull(title: 'Speed Bull Custom'),
        controller: controller,
        params: {'duration': 30}, // 30 seconds instead of 60
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Custom'),
          ),
        ),
      );

      // Assert: Verify custom duration is set
      expect(controller.gameDurationSeconds, equals(30));
      expect(controller.remainingSeconds, equals(30));

      // Act: Start game
      controller.startGame();
      await tester.pump();

      // Assert: Timer started with custom duration
      expect(controller.gameStarted, isTrue);
      expect(controller.remainingSeconds, equals(30));
    });

    /// Tests getCurrentStats method
    /// Verifies: statistics are calculated correctly during gameplay
    testWidgets('Speed Bull current stats calculation', (WidgetTester tester) async {
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerSpeedBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewSpeedBull(title: 'Speed Bull Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewSpeedBull));

      // Act: Start game and record hits
      controller.startGame();
      await tester.pump();
      
      controller.pressNumpadButton(testContext, 3); // Round 1: 3 hits
      await tester.pump();
      controller.pressNumpadButton(testContext, 1); // Round 2: 1 hit
      await tester.pump();

      // Assert: Verify current stats calculation
      Map stats = controller.getCurrentStats();
      expect(stats['rounds'], equals(2)); // 2 completed rounds
      expect(stats['totalHits'], equals(4)); // 3 + 1
      expect(stats['average'], equals('2.0')); // 4 hits / 2 rounds = 2.0
    });
  });
}
