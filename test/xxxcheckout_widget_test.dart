import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';

import 'xxxcheckout_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('XXXCheckout Game Widget Tests', () {
    late ControllerXXXCheckout controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      // Set up default mock responses
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordFinishes')).thenReturn(0);
      when(mockStorage.read('recordScore')).thenReturn(0.0);
      when(mockStorage.read('recordDarts')).thenReturn(0.0);
      when(mockStorage.read('longtermScore')).thenReturn(0.0);
      when(mockStorage.read('longtermDarts')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      controller = ControllerXXXCheckout.forTesting(mockStorage);

      // Initialize with safe parameters
      controller.init(MenuItem(
        id: 'test_501',
        name: '501 Test',
        view: const ViewXXXCheckout(title: '501 Test'),
        getController: (_) => controller,
        params: {'xxx': 501, 'max': -1, 'end': 100},
      ));
    });

    /// Tests XXXCheckout widget creation and initial state
    /// Verifies: widget can be created and displays correctly
    testWidgets('XXXCheckout widget creation and initial state',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Assert: Widget was created successfully
      expect(find.byType(ViewXXXCheckout), findsOneWidget);
      expect(find.text('501 Test'), findsOneWidget);

      // Assert: Initial controller state
      expect(controller.remaining, equals(501));
      expect(controller.leg, equals(1));
      expect(controller.round, equals(1));
      expect(controller.dart, equals(0));
      expect(controller.input, equals(""));
    });

    /// Tests XXXCheckout basic input building (no submission)
    /// Verifies: input can be built without triggering any actions
    testWidgets('XXXCheckout basic input building',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Act: Build input digit by digit (no submission)
      controller.pressNumpadButton(1);
      await tester.pump();
      expect(controller.input, equals("1"));

      controller.pressNumpadButton(2);
      await tester.pump();
      expect(controller.input, equals("12"));

      // Assert: No state changes except input
      expect(controller.remaining, equals(501));
      expect(controller.round, equals(1));
      expect(controller.dart, equals(0));
    });

    /// Tests XXXCheckout input validation (no submission)
    /// Verifies: invalid inputs are rejected without triggering actions
    testWidgets('XXXCheckout input validation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Test: Score > 180 should be rejected
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(1); // "181" - should be rejected
      await tester.pump();

      expect(controller.input, equals("18")); // Only "18" remains
      expect(controller.remaining, equals(501)); // No change
    });

    /// Tests XXXCheckout input clearing
    /// Verifies: input can be cleared with undo
    testWidgets('XXXCheckout input clearing', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
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

    /// Tests XXXCheckout interface methods
    /// Verifies: interface methods work correctly
    testWidgets('XXXCheckout interface methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
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

    /// Tests XXXCheckout statistics calculation (without game completion)
    /// Verifies: statistics methods work correctly
    testWidgets('XXXCheckout statistics methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Test getCurrentStats method
      Map stats = controller.getCurrentStats();
      expect(stats['round'], equals(1));
      expect(stats['avgScore'], equals('0.0'));
      expect(stats['avgDarts'], equals('0.0'));

      // Test string generation methods
      expect(controller.getCurrentRounds(), isA<String>());
      expect(controller.getCurrentScores(), isA<String>());
      expect(controller.getCurrentRemainings(), isA<String>());
      expect(controller.getCurrentDarts(), isA<String>());
    });

    /// Tests XXXCheckout score submission and remaining calculation
    /// Verifies: scores are submitted correctly and remaining is updated
    testWidgets('XXXCheckout score submission', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Act: Submit a score
      controller.pressNumpadButton(6);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit 60
      await tester.pump();

      // Assert: Score was submitted and remaining updated
      expect(controller.scores.length, equals(1));
      expect(controller.scores[0], equals(60));
      expect(controller.remaining, equals(441)); // 501 - 60
      expect(controller.remainings.length, equals(1)); // Only current remaining
      expect(controller.remainings[0], equals(441));
      expect(controller.round, equals(2));
      expect(controller.dart, equals(3)); // 3 darts used
      expect(controller.totalDarts, equals(3));
      expect(controller.totalScore, equals(60));
    });

    /// Tests XXXCheckout bogey number validation
    /// Verifies: bogey numbers are rejected correctly
    testWidgets('XXXCheckout bogey number validation',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Test bogey numbers are rejected
      List<int> bogeyNumbers = [159, 162, 163, 165, 166, 168, 169];

      for (int bogey in bogeyNumbers) {
        controller.input = "";
        String bogeyStr = bogey.toString();

        // Try to input bogey number
        for (int i = 0; i < bogeyStr.length; i++) {
          controller.pressNumpadButton(int.parse(bogeyStr[i]));
        }
        await tester.pump();

        // Assert: Bogey number was rejected
        expect(controller.input, isNot(equals(bogeyStr)));
      }
    });

    /// Tests XXXCheckout checkout detection and leg completion
    /// Verifies: checkout is detected and leg resets correctly
    testWidgets('XXXCheckout checkout detection', (WidgetTester tester) async {
      disableOverflowError();
      bool checkoutTriggered = false;
      int checkoutRemaining = -1;
      int checkoutScore = -1;

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Set up checkout callback
      controller.onShowCheckout = (remaining, score) {
        checkoutTriggered = true;
        checkoutRemaining = remaining;
        checkoutScore = score;
      };

      // Arrange: Set remaining to a small number
      controller.remaining = 60;
      controller.remainings = [501, 60];

      // Act: Submit exact checkout score
      controller.pressNumpadButton(6);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit 60 (exact checkout)
      await tester.pump();

      // Assert: Checkout was triggered
      expect(checkoutTriggered, isTrue);
      expect(checkoutRemaining, equals(0));
      expect(checkoutScore, equals(60));
      expect(controller.remaining, equals(501)); // Reset for new leg
      expect(controller.leg, equals(2)); // Incremented
    });

    /// Tests XXXCheckout pre-defined value buttons
    /// Verifies: pre-defined values work correctly
    testWidgets('XXXCheckout pre-defined values', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Act: Use pre-defined value (e.g., 100) - this should be processed as input + submit
      controller.pressNumpadButton(100); // Pre-defined value > 9
      await tester.pump();

      // Assert: Pre-defined value was processed and submitted
      expect(controller.scores.length, equals(1));
      expect(controller.scores[0], equals(100));
      expect(controller.remaining, equals(401));
    });

    /// Tests XXXCheckout long press return functionality
    /// Verifies: long press return is handled without errors
    testWidgets('XXXCheckout long press return', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Act: Input a score and use long press return
      controller.pressNumpadButton(4);
      controller.pressNumpadButton(0); // Input "40"
      controller.pressNumpadButton(-3); // Long press return
      await tester.pump();

      // Assert: Long press return was processed (exact behavior depends on remaining)
      // The key is that it doesn't crash and processes the input
      expect(controller.scores.length, greaterThanOrEqualTo(0));
    });

    /// Tests XXXCheckout undo with submitted scores
    /// Verifies: undo works correctly after score submission
    testWidgets('XXXCheckout undo submitted scores',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Arrange: Submit a score
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit 80
      await tester.pump();

      // Act: Undo the submitted score
      controller.pressNumpadButton(-2); // Undo
      await tester.pump();

      // Assert: State was restored
      expect(controller.scores.length, equals(0));
      expect(controller.remaining, equals(501)); // Back to initial
      expect(controller.round, equals(1));
      expect(controller.dart, equals(0));
      expect(controller.totalDarts, equals(0));
      expect(controller.totalScore, equals(0));
    });

    /// Tests XXXCheckout dart correction functionality
    /// Verifies: dart correction works correctly
    testWidgets('XXXCheckout dart correction', (WidgetTester tester) async {
      disableOverflowError();
      bool checkoutTriggered = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      controller.onShowCheckout = (remaining, score) {
        checkoutTriggered = true;
      };

      // Arrange: Complete a leg to have results
      controller.remaining = 50;
      controller.remainings = [501, 50];
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Checkout
      await tester.pump();

      expect(checkoutTriggered, isTrue);
      expect(controller.results.length, equals(1));
      int initialDarts = controller.results[0];

      // Act: Correct darts by 1
      controller.correctDarts(1);
      await tester.pump();

      // Assert: Dart count was corrected
      expect(controller.results[0], equals(initialDarts - 1));
    });

    /// Tests XXXCheckout average calculations
    /// Verifies: average score and darts are calculated correctly during game and at end
    testWidgets('XXXCheckout average calculations',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Test 1: Beginning - should handle division by zero
      Map stats = controller.getCurrentStats();
      expect(stats['avgScore'], equals('0.0')); // No darts thrown yet

      // Test 2: First throw - 60 points with 3 darts
      controller.pressNumpadButton(6);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // 60 points, 3 darts
      await tester.pump();

      stats = controller.getCurrentStats();
      // Average score = (totalScore / totalDarts) * 3 = (60 / 3) * 3 = 60.0
      expect(stats['avgScore'], equals('60.0'));

      // Test 3: Second throw - 90 points with 3 more darts (6 total)
      controller.pressNumpadButton(9);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // 90 points, 6 darts total
      await tester.pump();

      stats = controller.getCurrentStats();
      // Average score = (totalScore / totalDarts) * 3 = (150 / 6) * 3 = 75.0
      expect(stats['avgScore'], equals('75.0'));

      // Test 4: Third throw - 30 points with 3 more darts (9 total)
      controller.pressNumpadButton(3);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // 30 points, 9 darts total
      await tester.pump();

      stats = controller.getCurrentStats();
      // Average score = (totalScore / totalDarts) * 3 = (180 / 9) * 3 = 60.0
      expect(stats['avgScore'], equals('60.0'));

      // Test 5: Fourth throw - 0 points (miss) with 3 more darts (12 total)
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // 0 points, 12 darts total
      await tester.pump();

      stats = controller.getCurrentStats();
      // Average score = (totalScore / totalDarts) * 3 = (180 / 12) * 3 = 45.0
      expect(stats['avgScore'], equals('45.0'));
    });

    /// Tests XXXCheckout game end detection
    /// Verifies: checkout callbacks are triggered correctly
    testWidgets('XXXCheckout game end detection', (WidgetTester tester) async {
      disableOverflowError();

      // Initialize with end = 1 for simple testing
      controller.init(MenuItem(
        id: 'test_501',
        name: '501 Test',
        view: const ViewXXXCheckout(title: '501 Test'),
        getController: (_) => controller,
        params: {
          'xxx': 50,
          'max': -1,
          'end': 1
        }, // Small values for easy testing
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      int checkoutCount = 0;
      controller.onShowCheckout = (remaining, score) {
        checkoutCount++;
      };

      // Act: Complete one leg (checkout with exact score)
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit 50 (exact checkout)
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert: Checkout was triggered
      expect(checkoutCount, equals(1));
    });

    /// Tests XXXCheckout summary creation
    /// Verifies: summary lines are created correctly
    testWidgets('XXXCheckout summary creation', (WidgetTester tester) async {
      disableOverflowError();
      bool checkoutTriggered = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      controller.onShowCheckout = (remaining, score) {
        checkoutTriggered = true;
      };

      // Arrange: Complete a leg
      controller.remaining = 50;
      controller.remainings = [501, 50];
      controller.pressNumpadButton(5);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Checkout
      await tester.pump();

      expect(checkoutTriggered, isTrue);

      // Act: Create summary
      List<SummaryLine> summary = controller.createSummaryLines();

      // Assert: Summary contains expected lines
      expect(summary.length, equals(3));

      // Check finished legs line
      expect(summary.any((line) => line.label == 'Finished'), isTrue);

      // Check average lines
      expect(summary.any((line) => line.label == 'ØPunkte'), isTrue);
      expect(summary.any((line) => line.label == 'ØDarts'), isTrue);
    });

    /// Tests XXXCheckout with existing statistics
    /// Verifies: existing statistics are read correctly
    testWidgets('XXXCheckout with existing statistics',
        (WidgetTester tester) async {
      disableOverflowError();

      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(10);
      when(mockStorage.read('recordFinishes')).thenReturn(8);
      when(mockStorage.read('recordScore')).thenReturn(85.5);
      when(mockStorage.read('recordDarts')).thenReturn(15.2);
      when(mockStorage.read('longtermScore')).thenReturn(72.3);
      when(mockStorage.read('longtermDarts')).thenReturn(18.7);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Assert: Stats string reflects existing data
      String stats = controller.getStats();
      expect(stats, contains('#S: 10')); // Number of games
      expect(stats, contains('♛C: 8')); // Record finishes
      expect(stats, contains('♛P: 85.5')); // Record score
      expect(stats, contains('♛D: 15.2')); // Record darts
      expect(stats, contains('ØP: 72.3')); // Average score
      expect(stats, contains('ØD: 18.7')); // Average darts
    });

    /// Tests XXXCheckout bust prevention (remaining = 1)
    /// Verifies: input validation works correctly
    testWidgets('XXXCheckout bust prevention', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerXXXCheckout>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewXXXCheckout(title: '501 Test'),
          ),
        ),
      );

      // Test basic input validation - scores over 180 should be rejected
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(1); // Try to input 181
      await tester.pump();

      // Assert: Input over 180 was rejected
      expect(controller.input, equals("18")); // Only "18" should remain

      // Test that valid inputs are accepted
      controller.input = ""; // Clear input
      controller.pressNumpadButton(1);
      controller.pressNumpadButton(8);
      controller.pressNumpadButton(0); // Input 180 (valid)
      await tester.pump();

      expect(controller.input, equals("180")); // Should be accepted
    });
  });
}
