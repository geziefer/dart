import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/view/view_finishes.dart';
import 'package:dart/widget/menu.dart';

import 'finishes_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('Finishes Game Widget Tests', () {
    late ControllerFinishes controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      // Set up default mock responses
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('totalCorrectRounds')).thenReturn(0);
      when(mockStorage.read('totalRounds')).thenReturn(0);
      when(mockStorage.read('totalTimeAllGames')).thenReturn(0);
      when(mockStorage.read('recordPercentage')).thenReturn(0.0);
      when(mockStorage.read('recordAverageTime')).thenReturn(0.0);
      when(mockStorage.read('overallPercentage')).thenReturn(0.0);
      when(mockStorage.read('overallAverageTime')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      controller = ControllerFinishes.forTesting(mockStorage);

      // Initialize with safe parameters
      controller.init(MenuItem(
        id: 'test_finishes',
        name: 'Finishes Test',
        view: const ViewFinishes(title: 'Finishes Test'),
        getController: (_) => controller,
        params: {'from': 100, 'to': 170},
      ));
    });

    /// Tests Finishes widget creation and initial state
    /// Verifies: widget can be created and displays correctly
    testWidgets('Finishes widget creation and initial state',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Widget was created successfully
      expect(find.byType(ViewFinishes), findsOneWidget);
      expect(find.text('Finishes Test'), findsOneWidget);

      // Assert: Initial controller state
      expect(controller.currentRound, equals(1));
      expect(controller.correctRounds, equals(0));
      expect(controller.totalTimeSeconds, equals(0));
      expect(controller.currentState, equals(FinishesState.inputPreferred));
    });

    /// Tests Finishes finish generation
    /// Verifies: finish is generated within specified range
    testWidgets('Finishes finish generation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Current finish is within specified range
      expect(controller.currentFinish, greaterThanOrEqualTo(100));
      expect(controller.currentFinish, lessThanOrEqualTo(170));

      // Assert: Finish has valid preferred solution
      expect(controller.preferred, isNotEmpty);
      expect(controller.preferred, isA<List<String>>());
    });

    /// Tests Finishes text generation methods
    /// Verifies: text methods return correct information
    testWidgets('Finishes text generation methods',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Text methods return expected formats
      expect(controller.getPreferredText(), contains('Finish'));
      expect(controller.getPreferredText(),
          contains(controller.currentFinish.toString()));
      expect(controller.getRoundCounterText(), equals('Runde 1'));
      expect(controller.getPreferredInput(), equals('')); // Initially empty
      expect(controller.getAlternativeText(),
          equals('')); // Initially empty in preferred state
      expect(controller.getAlternativeInput(), equals('')); // Initially empty
      expect(controller.getResultSymbol(), equals('')); // Initially empty
      expect(controller.getResultTime(), equals('')); // Initially empty
      expect(controller.getSolutionText(), equals('')); // Initially empty
    });

    /// Tests Finishes statistics calculation (initial state)
    /// Verifies: statistics are calculated correctly at start
    testWidgets('Finishes initial statistics', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Initial statistics are correct
      Map stats = controller.getCurrentStats();
      expect(stats['round'], equals(1));
      expect(stats['correct'], equals(0));
      expect(stats['totalTime'], equals(0));
      expect(stats['averageTime'], equals('0.0'));
    });

    /// Tests Finishes statistics string generation
    /// Verifies: stats string is formatted correctly
    testWidgets('Finishes statistics string', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Stats string contains expected elements
      String stats = controller.getStats();
      expect(stats, contains('#S: 0')); // Number of games
      expect(stats, contains('♛P: 0.0%')); // Record percentage
      expect(stats, contains('♛Z: 0.0s')); // Record average time
      expect(stats, contains('ØP: 0.0%')); // Overall percentage
      expect(stats, contains('ØZ: 0.0s')); // Overall average time
    });

    /// Tests Finishes with existing statistics
    /// Verifies: existing statistics are read correctly
    testWidgets('Finishes with existing statistics',
        (WidgetTester tester) async {
      disableOverflowError();

      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('recordPercentage')).thenReturn(92.5);
      when(mockStorage.read('recordAverageTime')).thenReturn(8.7);
      when(mockStorage.read('overallPercentage')).thenReturn(78.3);
      when(mockStorage.read('overallAverageTime')).thenReturn(12.4);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Stats string reflects existing data
      String stats = controller.getStats();
      expect(stats, contains('#S: 5')); // Number of games
      expect(stats, contains('♛P: 92.5%')); // Record percentage
      expect(stats, contains('♛Z: 8.7s')); // Record average time
      expect(stats, contains('ØP: 78.3%')); // Overall percentage
      expect(stats, contains('ØZ: 12.4s')); // Overall average time
    });

    /// Tests Finishes range validation
    /// Verifies: different ranges generate appropriate finishes
    testWidgets('Finishes range validation', (WidgetTester tester) async {
      disableOverflowError();

      // Test with narrow range
      controller.init(MenuItem(
        id: 'test_finishes_narrow',
        name: 'Finishes Narrow Test',
        view: const ViewFinishes(title: 'Finishes Narrow Test'),
        getController: (_) => controller,
        params: {'from': 150, 'to': 160}, // Narrow range
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Narrow Test'),
          ),
        ),
      );

      // Assert: Current finish is within narrow range
      expect(controller.currentFinish, greaterThanOrEqualTo(150));
      expect(controller.currentFinish, lessThanOrEqualTo(160));

      // Assert: Text reflects the new finish
      expect(controller.getPreferredText(),
          contains(controller.currentFinish.toString()));
    });

    /// Tests Finishes state enum
    /// Verifies: state enum values are accessible
    testWidgets('Finishes state enum values', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: State enum values are accessible
      expect(FinishesState.inputPreferred, isA<FinishesState>());
      expect(FinishesState.inputAlternative, isA<FinishesState>());
      expect(FinishesState.solution, isA<FinishesState>());

      // Assert: Initial state is correct
      expect(controller.currentState, equals(FinishesState.inputPreferred));
    });

    /// Tests Finishes finish data structure
    /// Verifies: finish data is properly structured
    testWidgets('Finishes data structure validation',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Assert: Preferred finish is valid
      expect(controller.preferred, isA<List<String>>());
      expect(controller.preferred.isNotEmpty, isTrue);

      // Assert: Alternative finish is valid (can be empty)
      expect(controller.alternative, isA<List<String>>());

      // Assert: Finish exists in static data
      expect(ControllerFinishes.finishes.containsKey(controller.currentFinish),
          isTrue);
    });

    /// Tests Finishes average calculation
    /// Verifies: average time calculation works correctly during game and at end
    testWidgets('Finishes average calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerFinishes>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewFinishes(title: 'Finishes Test'),
          ),
        ),
      );

      // Test 1: Beginning - should handle division by zero
      Map stats = controller.getCurrentStats();
      expect(stats['averageTime'], equals('0.0')); // No finishes completed yet

      // Test 2: Simulate completing first finish by manually setting time
      controller.totalTimeSeconds = 5; // Simulate 5 seconds
      controller.currentRound = 2; // Simulate moving to round 2 (1 completed)
      
      stats = controller.getCurrentStats();
      expect(stats['averageTime'], equals('5.0')); // 5 seconds / 1 round = 5.0

      // Test 3: Simulate completing second finish
      controller.totalTimeSeconds = 12; // Total 12 seconds (5 + 7)
      controller.currentRound = 3; // Simulate moving to round 3 (2 completed)
      
      stats = controller.getCurrentStats();
      expect(stats['averageTime'], equals('6.0')); // 12 seconds / 2 rounds = 6.0

      // Test 4: Simulate completing third finish
      controller.totalTimeSeconds = 15; // Total 15 seconds (12 + 3)
      controller.currentRound = 4; // Simulate moving to round 4 (3 completed)
      
      stats = controller.getCurrentStats();
      expect(stats['averageTime'], equals('5.0')); // 15 seconds / 3 rounds = 5.0

      // Test 5: Simulate completing more rounds and verify calculation
      controller.totalTimeSeconds = 40; // Total 40 seconds
      controller.currentRound = 6; // Simulate 5 completed rounds
      
      stats = controller.getCurrentStats();
      expect(stats['averageTime'], equals('8.0')); // 40 seconds / 5 rounds = 8.0
    });
  });
}
