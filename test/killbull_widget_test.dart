import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_killbull.dart';
import 'package:dart/view/view_killbull.dart';
import 'package:dart/widget/menu.dart';

// Generate mocks
@GenerateMocks([GetStorage])
import 'killbull_widget_test.mocks.dart';

void main() {
  group('Kill Bull Game Widget Tests', () {
    late ControllerKillBull controller;
    late MockGetStorage mockStorage;

    setUpAll(() {
      // Setup that runs once for all tests
    });

    setUp(() {
      // Create fresh mock storage for each test (clean isolation)
      mockStorage = MockGetStorage();
      
      // Set up default mock responses (simulate fresh game stats)
      // IMPORTANT: longtermScore must be double, others can be int
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordRounds')).thenReturn(0);
      when(mockStorage.read('recordScore')).thenReturn(0);
      when(mockStorage.read('longtermScore')).thenReturn(0.0); // Must be double!
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      // Create controller with injected mock storage
      controller = ControllerKillBull.forTesting(mockStorage);
      
      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_killbull',
        name: 'Kill Bull Test',
        view: const ViewKillBull(title: 'Kill Bull Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    /// Tests a complete Kill Bull game from start to finish including summary dialog
    /// Verifies: score calculations, round progression, game ending, summary dialog, storage interactions
    /// Scenario: Player hits 3, 2, then 0 bulls (3 rounds total)
    testWidgets('Complete Kill Bull game workflow - basic scenario', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      // Arrange: Set up the game widget
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Assert: Verify initial state
      expect(controller.round, equals(1));
      expect(controller.totalScore, equals(0));
      expect(controller.gameEnded, isFalse);

      // Act: Round 1 - Hit 3 bulls
      controller.pressNumpadButton(3);
      await tester.pumpAndSettle();

      // Assert: Verify round 1 results
      expect(controller.round, equals(2));
      expect(controller.totalScore, equals(75)); // 3 * 25 = 75
      expect(controller.roundScores.length, equals(1));
      expect(controller.roundScores[0], equals(75));
      expect(controller.gameEnded, isFalse);

      // Act: Round 2 - Hit 2 bulls  
      controller.pressNumpadButton(2);
      await tester.pumpAndSettle();

      // Assert: Verify round 2 results
      expect(controller.round, equals(3));
      expect(controller.totalScore, equals(125)); // 75 + 50 = 125
      expect(controller.roundScores.length, equals(2));
      expect(controller.roundScores[1], equals(50));

      // Act: Round 3 - Hit 0 bulls (game should end)
      controller.pressNumpadButton(0);
      await tester.pumpAndSettle();
      
      // Wait a bit more for the post-frame callback to execute
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Assert: Verify game ended correctly
      expect(controller.gameEnded, isTrue);
      expect(controller.totalScore, equals(125));
      expect(controller.roundScores.length, equals(3));
      expect(controller.roundScores[2], equals(0));

      // Assert: Verify summary dialog appears with correct data
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Runden: 3'), findsOneWidget); // Round when game ended
      expect(find.text('Punkte: 125'), findsOneWidget); // Total score

      // Assert: Verify storage interactions (focus on operations occurring)
      verify(mockStorage.read('numberGames')).called(greaterThan(0));
      verify(mockStorage.read('recordRounds')).called(greaterThan(0));
      verify(mockStorage.read('recordScore')).called(greaterThan(0));
      verify(mockStorage.read('longtermScore')).called(greaterThan(0));
      verify(mockStorage.write('numberGames', 1)).called(1); // First game
      verify(mockStorage.write('recordRounds', 3)).called(1); // Round when game ended
      verify(mockStorage.write('recordScore', 125)).called(1); // Total score 125
      verify(mockStorage.write('longtermScore', 125.0)).called(1); // Long-term average of total scores: 125.0 for first game
    });

    /// Tests the undo functionality during gameplay
    /// Verifies: undo removes last round, scores recalculate correctly, no premature storage writes
    testWidgets('Kill Bull undo functionality test', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Act: Round 1 - Hit 4 bulls
      controller.pressNumpadButton(4);
      await tester.pumpAndSettle();
      
      // Assert: Verify first round
      expect(controller.totalScore, equals(100)); // 4 * 25
      expect(controller.round, equals(2));

      // Act: Round 2 - Hit 3 bulls
      controller.pressNumpadButton(3);
      await tester.pumpAndSettle();
      
      // Assert: Verify second round
      expect(controller.totalScore, equals(175)); // 100 + 75
      expect(controller.round, equals(3));

      // Act: Press undo button (value -2)
      controller.pressNumpadButton(-2);
      await tester.pumpAndSettle();

      // Assert: Verify undo worked correctly
      expect(controller.totalScore, equals(100)); // Back to first round score
      expect(controller.round, equals(2)); // Back to round 2
      expect(controller.roundScores.length, equals(1));

      // Act: Continue and end game
      controller.pressNumpadButton(1);
      await tester.pumpAndSettle();
      controller.pressNumpadButton(0);
      await tester.pumpAndSettle();
      
      // Assert: Game ends properly
      expect(controller.gameEnded, isTrue);
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage only called at game end, not during undo
      verify(mockStorage.write(any, any)).called(4); // Only 4 writes at game end
    });

    /// Tests storage interaction with existing game statistics
    /// Verifies: storage operations occur when game ends
    testWidgets('Kill Bull with existing game statistics', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('recordRounds')).thenReturn(8);
      when(mockStorage.read('recordScore')).thenReturn(200);
      when(mockStorage.read('longtermScore')).thenReturn(150.0);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Act: Play a simple game and end it
      controller.pressNumpadButton(6); // 150 points
      await tester.pumpAndSettle();
      controller.pressNumpadButton(0); // End game
      await tester.pumpAndSettle();

      // Assert: Verify storage operations that actually occur
      verify(mockStorage.write('numberGames', 6)).called(1); // Game count updated (5+1)
      verify(mockStorage.write('longtermScore', 150.0)).called(1); // Average updated
      // Note: Records not updated because new game (1 round, 150 points) 
      // doesn't beat existing records (8 rounds, 200 points)
    });

    /// Tests return button functionality
    /// Verifies: return button (value -1) functions as 0 bulls input
    testWidgets('Kill Bull return button for zero bulls', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Act: Hit 5 bulls, then use return button
      controller.pressNumpadButton(5);
      await tester.pumpAndSettle();
      controller.pressNumpadButton(-1); // Return button
      await tester.pumpAndSettle();

      // Assert: Game ended with return button working as 0 bulls
      expect(controller.gameEnded, isTrue);
      expect(controller.roundScores.last, equals(0));
      expect(find.byType(Dialog), findsOneWidget);
    });

    /// Tests immediate game ending scenario
    /// Verifies: game can end on first round, storage handles zero stats correctly
    testWidgets('Kill Bull immediate game end', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Act: Hit 0 bulls immediately
      controller.pressNumpadButton(0);
      await tester.pumpAndSettle();

      // Assert: Verify immediate game end
      expect(controller.gameEnded, isTrue);
      expect(controller.totalScore, equals(0));
      expect(controller.getCurrentStats()['avgScore'], equals('0.0'));
      expect(find.byType(Dialog), findsOneWidget);

      // Assert: Verify storage handles zero values correctly
      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('recordRounds', 1)).called(1); // 1 round played
      verify(mockStorage.write('recordScore', 0)).called(1); // 0 score
      verify(mockStorage.write('longtermScore', 0.0)).called(1); // 0 average
    });

    /// Tests extended game scenario with statistics verification
    /// Verifies: longer games calculate statistics correctly
    testWidgets('Kill Bull extended game scenario', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Act: Play extended game
      List<int> bullsPerRound = [6, 5, 4, 3, 2, 1, 6, 0]; // 8 rounds, 675 points
      for (int bulls in bullsPerRound) {
        controller.pressNumpadButton(bulls);
        await tester.pumpAndSettle();
      }

      // Assert: Verify final state and storage
      expect(controller.totalScore, equals(675));
      expect(controller.roundScores.length, equals(8));
      expect(find.byType(Dialog), findsOneWidget);
      
      verify(mockStorage.write('recordScore', 675)).called(1);
      verify(mockStorage.write('recordRounds', 8)).called(1);
    });

    /// Tests undo edge cases
    /// Verifies: undo doesn't work when no rounds played, undo doesn't work after game ends
    testWidgets('Kill Bull undo edge cases', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Act: Try undo with no rounds played
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Nothing should change
      expect(controller.round, equals(1));
      expect(controller.totalScore, equals(0));
      expect(controller.roundScores.length, equals(0));

      // Act: Play and end game
      controller.pressNumpadButton(3);
      await tester.pump();
      controller.pressNumpadButton(0);
      await tester.pump();
      
      // Assert: Game ended
      expect(controller.gameEnded, isTrue);
      expect(controller.totalScore, equals(75)); // 3 * 25

      // Act: Try undo after game ended
      int scoreBeforeUndo = controller.totalScore;
      bool gameEndedBefore = controller.gameEnded;
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Undo should not work after game ended
      expect(controller.totalScore, equals(scoreBeforeUndo));
      expect(controller.gameEnded, equals(gameEndedBefore));
    });

    /// Tests score calculation accuracy with basic storage verification
    /// Verifies: score calculations work and storage operations occur
    testWidgets('Kill Bull score calculation verification', (WidgetTester tester) async {
      // Disable overflow errors for this test
      disableOverflowError();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerKillBull>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewKillBull(title: 'Kill Bull Test'),
          ),
        ),
      );


      // Test a simple case: 3 bulls = 75 points
      controller.pressNumpadButton(3);
      await tester.pump();
      
      // Assert: Verify score calculation
      expect(controller.totalScore, equals(75)); // 3 * 25 = 75
      expect(controller.roundScores[0], equals(75));
      
      // End game and verify storage occurs
      controller.pressNumpadButton(0);
      await tester.pump();
      
      // Assert: Just verify that storage operations occurred
      verify(mockStorage.write(any, any)).called(greaterThan(0)); // Some storage operations happened
      expect(controller.gameEnded, isTrue);
    });
  });
}
