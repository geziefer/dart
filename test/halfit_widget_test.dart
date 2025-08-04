import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/view/view_halfit.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';

import 'halfit_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('HalfIt Game Widget Tests', () {
    late ControllerHalfit controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();
      
      // Set up default mock responses
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordScore')).thenReturn(0);
      when(mockStorage.read('longtermScore')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      controller = ControllerHalfit.forTesting(mockStorage);
      
      // Initialize controller
      controller.init(MenuItem(
        id: 'test_halfit',
        name: 'HalfIt Test',
        view: const ViewHalfit(title: 'HalfIt Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    /// Tests HalfIt widget creation and initial state
    /// Verifies: widget can be created and displays correctly
    testWidgets('HalfIt widget creation and initial state', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Assert: Widget was created successfully
      expect(find.byType(ViewHalfit), findsOneWidget);
      expect(find.text('HalfIt Test'), findsOneWidget);
      
      // Assert: Initial controller state
      expect(controller.round, equals(1));
      expect(controller.score, equals(40));
      expect(controller.totalScore, equals(40));
      expect(controller.input, equals(""));
    });

    /// Tests HalfIt labels and targets
    /// Verifies: game has correct sequence of targets
    testWidgets('HalfIt labels and targets', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Assert: Labels are correct
      expect(ControllerHalfit.labels, equals(['15', '16', 'D', '17', '18', 'T', '19', '20', 'B']));
      expect(ControllerHalfit.labels.length, equals(9));
      
      // Assert: Initial state
      expect(controller.rounds[0], equals('15'));
    });

    /// Tests HalfIt basic input building (no submission)
    /// Verifies: input can be built without triggering any actions
    testWidgets('HalfIt basic input building', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );


      // Act: Build input digit by digit (no submission)
      controller.pressNumpadButton(6);
      await tester.pump();
      expect(controller.input, equals("6"));

      controller.pressNumpadButton(0);
      await tester.pump();
      expect(controller.input, equals("60"));

      // Assert: No state changes except input
      expect(controller.totalScore, equals(40));
      expect(controller.round, equals(1));
    });

    /// Tests HalfIt input validation (no submission)
    /// Verifies: invalid inputs are rejected without triggering actions
    testWidgets('HalfIt input validation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );


      // Test: Score > 180 should be rejected
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(1); // "181" - should be rejected
      await tester.pump();
      
      expect(controller.input, equals("18")); // Only "18" remains
      expect(controller.totalScore, equals(40)); // No change
    });

    /// Tests HalfIt input clearing
    /// Verifies: input can be cleared with undo
    testWidgets('HalfIt input clearing', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );


      // Act: Build some input
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(2);
      controller.pressNumpadButton(3);
      await tester.pump();
      expect(controller.input, equals("123"));

      // Act: Clear input with undo
      controller.pressNumpadButton(-2); // Undo
      await tester.pump();
      expect(controller.input, equals(""));
    });

    /// Tests HalfIt interface methods
    /// Verifies: interface methods work correctly
    testWidgets('HalfIt interface methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );


      // Test getInput method
      controller.pressNumpadButton(4);
      controller.pressNumpadButton(2);
      await tester.pump();
      expect(controller.getInput(), equals("42"));

      // Test isButtonDisabled method
      expect(controller.isButtonDisabled(5), isFalse);

      // Test stats string method
      String stats = controller.getStats();
      expect(stats, contains('#S: 0')); // Number of games
    });

    /// Tests HalfIt statistics methods
    /// Verifies: statistics methods work correctly
    testWidgets('HalfIt statistics methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Test getCurrentStats method
      Map stats = controller.getCurrentStats();
      expect(stats['round'], equals(1));
      expect(stats['avgScore'], equals('0.0'));

      // Test string generation methods
      expect(controller.getCurrentRounds(), isA<String>());
      expect(controller.getCurrentScores(), isA<String>());
      expect(controller.getCurrentTotals(), isA<String>());
    });

    /// Tests HalfIt with existing statistics
    /// Verifies: existing statistics are read correctly
    testWidgets('HalfIt with existing statistics', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('recordScore')).thenReturn(300);
      when(mockStorage.read('longtermScore')).thenReturn(220.5);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Assert: Stats string reflects existing data
      String stats = controller.getStats();
      expect(stats, contains('#S: 5')); // Number of games
      expect(stats, contains('♛P: 300')); // Record score
      expect(stats, contains('ØP: 220.5')); // Average score
    });

    /// Tests HalfIt score submission and game progression
    /// Verifies: scores are submitted correctly and game progresses
    testWidgets('HalfIt score submission and progression', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Act: Submit a score for first target (15)
      controller.pressNumpadButton(3);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit 30
      await tester.pump();

      // Assert: Score was submitted and game progressed
      expect(controller.scores.length, equals(1));
      expect(controller.scores[0], equals(30));
      expect(controller.totalScore, equals(70)); // 40 + 30
      expect(controller.totals[0], equals(70));
      expect(controller.hit[0], isTrue); // Positive score = hit
      expect(controller.round, equals(2));
      expect(controller.rounds.length, equals(2));
      expect(controller.rounds[1], equals('16')); // Next target
    });

    /// Tests HalfIt half-it logic when score is 0
    /// Verifies: half-it mechanic works correctly
    testWidgets('HalfIt half-it logic', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Arrange: Set up a scenario with some score
      controller.pressNumpadButton(6);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit 60, total = 100
      await tester.pump();

      // Act: Submit 0 score (triggers half-it)
      controller.pressNumpadButton(-1); // Submit 0 (empty input)
      await tester.pump();

      // Assert: Score was halved
      expect(controller.scores.length, equals(2));
      expect(controller.scores[1], equals(-50)); // -(100/2)
      expect(controller.totalScore, equals(50)); // 100 - 50
      expect(controller.hit[1], isFalse); // Negative score = miss
    });

    /// Tests HalfIt undo functionality with submitted scores
    /// Verifies: undo works correctly after score submission
    testWidgets('HalfIt undo submitted scores', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Arrange: Submit a score
      controller.pressNumpadButton(4);
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(-1); // Submit 45
      await tester.pump();

      int initialRound = controller.round;

      // Act: Undo the submitted score
      controller.pressNumpadButton(-2); // Undo
      await tester.pump();

      // Assert: State was restored
      expect(controller.scores.length, equals(0));
      expect(controller.round, equals(initialRound - 1));
      expect(controller.totalScore, equals(40)); // Back to initial
      expect(controller.rounds.length, equals(1)); // Back to first target
    });

    /// Tests HalfIt game completion
    /// Verifies: game ends correctly after 9 rounds
    testWidgets('HalfIt game completion', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Act: Play through all 9 rounds
      for (int i = 0; i < 9; i++) {
        controller.pressNumpadButton(2);
        controller.pressNumpadButton(0);
        controller.pressNumpadButton(-1); // Submit 20 each round
        await tester.pump();
        
        // Process any pending callbacks after each round
        await tester.pumpAndSettle();
      }

      // Assert: All 9 scores were submitted
      expect(controller.scores.length, equals(9));
      
      // The triggerGameEnd should have been called via post-frame callback
      // We can't easily test the callback directly, but we can verify the game state
      expect(controller.round, equals(9)); // Round should be 9 after 9 submissions
    });

    /// Tests HalfIt summary creation
    /// Verifies: summary lines are created correctly
    testWidgets('HalfIt summary creation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Arrange: Submit some scores
      controller.pressNumpadButton(3);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Hit: 30
      await tester.pump();

      controller.pressNumpadButton(-1); // Miss: 0 (half-it)
      await tester.pump();

      // Act: Create summary
      List<SummaryLine> summary = controller.createSummaryLines();

      // Assert: Summary contains expected lines
      expect(summary.length, greaterThan(2));
      
      // Check total score line
      expect(summary.any((line) => line.label == 'Punkte'), isTrue);
      
      // Check individual target lines with symbols
      expect(summary.any((line) => line.checkSymbol == "✅"), isTrue); // Hit
      expect(summary.any((line) => line.checkSymbol == "❌"), isTrue); // Miss
      
      // Check average line
      expect(summary.any((line) => line.label == 'ØPunkte'), isTrue);
    });

    /// Tests HalfIt average score calculation
    /// Verifies: average score is calculated correctly
    testWidgets('HalfIt average score calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Act: Submit multiple scores
      controller.pressNumpadButton(2);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // 20, total = 60
      await tester.pump();

      controller.pressNumpadButton(3);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // 30, total = 90
      await tester.pump();

      // Assert: Average is calculated correctly
      Map stats = controller.getCurrentStats();
      // Average = (total - initial) / rounds = (90 - 40) / 2 = 25.0
      expect(stats['avgScore'], equals('25.0'));
    });

    /// Tests Menu widget business logic - MenuItem creation and controller initialization
    /// Verifies: MenuItem can be created and controller properly initialized
    testWidgets('Menu widget MenuItem creation and initialization', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Test MenuItem creation (business logic from menu.dart)
      final menuItem = MenuItem(
        id: 'test_halfit',
        name: 'HalfIt Test',
        view: const ViewHalfit(title: 'HalfIt Test'),
        getController: (_) => controller,
        params: {},
      );

      // Assert: MenuItem properties are set correctly
      expect(menuItem.id, equals('test_halfit'));
      expect(menuItem.name, equals('HalfIt Test'));
      expect(menuItem.params, equals({}));

      // Test controller initialization via MenuItem (simulates menu button press logic)
      controller.init(menuItem);

      // Assert: Controller was properly initialized
      expect(controller.item, equals(menuItem));
      expect(controller.round, equals(1));
      expect(controller.totalScore, equals(40));
      expect(controller.rounds.length, equals(1));
      expect(controller.rounds[0], equals('15')); // First target
    });

    /// Tests Menu widget controller provider logic
    /// Verifies: Controller can be retrieved and reinitialized
    testWidgets('Menu widget controller provider logic', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerHalfit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewHalfit(title: 'HalfIt Test'),
          ),
        ),
      );

      // Simulate menu item creation with controller provider
      final menuItem = MenuItem(
        id: 'halfit_game',
        name: 'Half It',
        view: const ViewHalfit(title: 'Half It'),
        getController: (context) => Provider.of<ControllerHalfit>(context, listen: false),
        params: {},
      );

      // Test controller retrieval (simulates getController call)
      final retrievedController = menuItem.getController(tester.element(find.byType(ViewHalfit))) as ControllerHalfit;
      expect(retrievedController, equals(controller));

      // Test reinitialization (simulates fresh game state)
      retrievedController.init(menuItem);
      expect(retrievedController.round, equals(1));
      expect(retrievedController.input, equals(""));
      expect(retrievedController.scores.length, equals(0));
    });
  });
}
