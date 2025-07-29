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
        controller: controller,
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

      final testContext = tester.element(find.byType(ViewHalfit));

      // Act: Build input digit by digit (no submission)
      controller.pressNumpadButton(testContext, 6);
      await tester.pump();
      expect(controller.input, equals("6"));

      controller.pressNumpadButton(testContext, 0);
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

      final testContext = tester.element(find.byType(ViewHalfit));

      // Test: Score > 180 should be rejected
      controller.pressNumpadButton(testContext, 1);
      controller.pressNumpadButton(testContext, 8);
      controller.pressNumpadButton(testContext, 1); // "181" - should be rejected
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

      final testContext = tester.element(find.byType(ViewHalfit));

      // Act: Build some input
      controller.pressNumpadButton(testContext, 1);
      controller.pressNumpadButton(testContext, 2);
      controller.pressNumpadButton(testContext, 3);
      await tester.pump();
      expect(controller.input, equals("123"));

      // Act: Clear input with undo
      controller.pressNumpadButton(testContext, -2); // Undo
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

      final testContext = tester.element(find.byType(ViewHalfit));

      // Test getInput method
      controller.pressNumpadButton(testContext, 4);
      controller.pressNumpadButton(testContext, 2);
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
  });
}
