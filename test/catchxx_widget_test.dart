import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/view/view_catchxx.dart';
import 'package:dart/widget/menu.dart';

import 'catchxx_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('CatchXX Game Widget Tests', () {
    late ControllerCatchXX controller;
    late MockGetStorage mockStorage;
    late BuildContext testContext;

    setUp(() {
      mockStorage = MockGetStorage();
      
      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordHits')).thenReturn(0);
      when(mockStorage.read('recordPoints')).thenReturn(0);
      when(mockStorage.read('longtermPoints')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
      
      // Create controller with injected mock storage
      controller = ControllerCatchXX.forTesting(mockStorage);
      
      // Initialize controller
      controller.init(MenuItem(
        id: 'test_catchxx',
        name: 'CatchXX Test',
        view: const ViewCatchXX(title: 'CatchXX Test'),
        controller: controller,
        params: {}, // No specific parameters needed
      ));
    });

    /// Tests CatchXX widget creation and initial state
    /// Verifies: widget can be created and displays correctly
    testWidgets('CatchXX widget creation and initial state', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Assert: Widget was created successfully
      expect(find.byType(ViewCatchXX), findsOneWidget);
      expect(find.text('CatchXX Test'), findsOneWidget);
      
      // Assert: Initial controller state
      expect(controller.target, equals(61)); // Starting target
      expect(controller.round, equals(1)); // First round
      expect(controller.hits, equals(0)); // No hits yet
      expect(controller.points, equals(0)); // No points yet
      expect(controller.targets.length, equals(1)); // One target (61)
      expect(controller.targets[0], equals(61));
    });

    /// Tests CatchXX basic scoring functionality
    /// Verifies: points are calculated correctly based on darts used
    testWidgets('CatchXX basic scoring functionality', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Finish target 61 in 2 darts (should get 3 points)
      controller.pressNumpadButton(testContext, 2); // 2 darts
      await tester.pump();

      // Assert: 2 darts scored correctly
      expect(controller.hits, equals(1)); // 1 hit
      expect(controller.points, equals(3)); // 3 points for 2 darts
      expect(controller.target, equals(62)); // Advanced to next target
      expect(controller.round, equals(2)); // Advanced to round 2
      expect(controller.thrownPoints[0], equals(3)); // 3 points recorded

      // Act: Finish target 62 in 3 darts (should get 2 points)
      controller.pressNumpadButton(testContext, 3); // 3 darts
      await tester.pump();

      // Assert: 3 darts scored correctly
      expect(controller.hits, equals(2)); // 2 hits total
      expect(controller.points, equals(5)); // 3 + 2 = 5 points total
      expect(controller.target, equals(63)); // Advanced to next target
      expect(controller.thrownPoints[1], equals(2)); // 2 points recorded
    });

    /// Tests CatchXX different dart counts scoring
    /// Verifies: all dart count scenarios score correctly
    testWidgets('CatchXX different dart counts scoring', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Test different dart counts
      final testCases = [
        {'darts': 2, 'expectedPoints': 3},
        {'darts': 3, 'expectedPoints': 2},
        {'darts': 4, 'expectedPoints': 1},
        {'darts': 5, 'expectedPoints': 1},
        {'darts': 6, 'expectedPoints': 1},
      ];

      int totalPoints = 0;
      int totalHits = 0;

      for (int i = 0; i < testCases.length; i++) {
        int darts = testCases[i]['darts'] as int;
        int expectedPoints = testCases[i]['expectedPoints'] as int;
        
        controller.pressNumpadButton(testContext, darts);
        await tester.pump();
        
        totalPoints += expectedPoints;
        totalHits += 1;
        
        expect(controller.points, equals(totalPoints));
        expect(controller.hits, equals(totalHits));
        expect(controller.target, equals(61 + i + 1)); // Target advances
      }
    });

    /// Tests CatchXX no score scenarios
    /// Verifies: no score scenarios (0 darts, return button) work correctly
    testWidgets('CatchXX no score scenarios', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Use return button (no score)
      controller.pressNumpadButton(testContext, -1); // Return button
      await tester.pump();

      // Assert: No score recorded
      expect(controller.hits, equals(0)); // No hits
      expect(controller.points, equals(0)); // No points
      expect(controller.target, equals(62)); // Target still advances
      expect(controller.thrownPoints[0], equals(0)); // 0 points recorded

      // Act: Use 0 button (no score)
      controller.pressNumpadButton(testContext, 0); // 0 button
      await tester.pump();

      // Assert: No score recorded
      expect(controller.hits, equals(0)); // Still no hits
      expect(controller.points, equals(0)); // Still no points
      expect(controller.target, equals(63)); // Target advances
      expect(controller.thrownPoints[1], equals(0)); // 0 points recorded
    });

    /// Tests CatchXX button 1 disabled functionality
    /// Verifies: button 1 is ignored (impossible to finish in 1 dart)
    testWidgets('CatchXX button 1 disabled', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Try to use button 1 (should be ignored)
      controller.pressNumpadButton(testContext, 1); // Button 1
      await tester.pump();

      // Assert: Button 1 was ignored
      expect(controller.hits, equals(0)); // No change
      expect(controller.points, equals(0)); // No change
      expect(controller.target, equals(61)); // No change
      expect(controller.round, equals(1)); // No change
      expect(controller.thrownPoints.isEmpty, isTrue); // No points recorded

      // Assert: isButtonDisabled returns true for button 1
      expect(controller.isButtonDisabled(1), isTrue);
    });

    /// Tests CatchXX target 99 special case
    /// Verifies: target 99 has special scoring (impossible to finish in 2 darts)
    testWidgets('CatchXX target 99 special case', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Advance to target 99 (skip many targets to avoid long test)
      // Set target directly for testing purposes
      controller.target = 99;
      controller.round = 39; // Corresponding round

      // Assert: Button 2 is disabled for target 99
      expect(controller.isButtonDisabled(2), isTrue);
      expect(controller.isButtonDisabled(3), isFalse); // Button 3 should work

      // Act: Finish target 99 in 3 darts (special case: 3 points)
      controller.pressNumpadButton(testContext, 3); // 3 darts on target 99
      await tester.pump();

      // Assert: Target 99 scored correctly (3 points for 3 darts)
      expect(controller.points, equals(3)); // 3 points for 3 darts on 99
      expect(controller.hits, equals(1)); // 1 hit
      expect(controller.target, equals(100)); // Advanced to target 100
    });

    /// Tests CatchXX undo functionality
    /// Verifies: undo removes last round, restores previous state
    testWidgets('CatchXX undo functionality', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Play a few rounds
      controller.pressNumpadButton(testContext, 2); // 3 points
      await tester.pump();
      controller.pressNumpadButton(testContext, 3); // 2 points
      await tester.pump();

      // Assert: Verify state before undo
      expect(controller.hits, equals(2));
      expect(controller.points, equals(5)); // 3 + 2
      expect(controller.target, equals(63));
      expect(controller.round, equals(3));

      // Act: Undo last round
      controller.pressNumpadButton(testContext, -2); // Undo button
      await tester.pump();

      // Assert: Verify undo worked
      expect(controller.hits, equals(1)); // Back to 1 hit
      expect(controller.points, equals(3)); // Back to 3 points
      expect(controller.target, equals(62)); // Back to target 62
      expect(controller.round, equals(2)); // Back to round 2
      expect(controller.thrownPoints.length, equals(1)); // One entry removed
    });

    /// Tests CatchXX undo edge cases
    /// Verifies: undo doesn't work when no rounds played
    testWidgets('CatchXX undo edge cases', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Try to undo when no rounds have been played
      controller.pressNumpadButton(testContext, -2); // Undo button
      await tester.pump();

      // Assert: Undo had no effect (no rounds to undo)
      expect(controller.hits, equals(0));
      expect(controller.points, equals(0));
      expect(controller.target, equals(61));
      expect(controller.round, equals(1));
      expect(controller.thrownPoints.isEmpty, isTrue);
    });

    /// Tests CatchXX statistics calculation
    /// Verifies: statistics are calculated correctly during gameplay
    testWidgets('CatchXX statistics calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Play a few rounds
      controller.pressNumpadButton(testContext, 2); // 3 points
      await tester.pump();
      controller.pressNumpadButton(testContext, 4); // 1 point
      await tester.pump();
      controller.pressNumpadButton(testContext, 3); // 2 points
      await tester.pump();

      // Assert: Verify statistics calculation
      Map stats = controller.getCurrentStats();
      expect(stats['target'], equals(64)); // Current target
      expect(stats['hits'], equals(3)); // 3 hits
      expect(stats['points'], equals(6)); // 3 + 1 + 2 = 6 points
      expect(stats['avgPoints'], equals('2.0')); // 6 points / 3 rounds = 2.0
    });

    /// Tests CatchXX string generation methods
    /// Verifies: string methods return properly formatted data
    testWidgets('CatchXX string generation methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Play a few rounds to generate data
      controller.pressNumpadButton(testContext, 2); // Target 61: 3 points
      controller.pressNumpadButton(testContext, 3); // Target 62: 2 points
      await tester.pump();

      // Assert: String methods return valid data
      expect(controller.getCurrentTargets(), isA<String>());
      expect(controller.getCurrentThrownPoints(), isA<String>());
      expect(controller.getCurrentTotalPoints(), isA<String>());
      
      // Assert: String methods contain expected data patterns
      String targets = controller.getCurrentTargets();
      String thrownPoints = controller.getCurrentThrownPoints();
      String totalPoints = controller.getCurrentTotalPoints();
      
      expect(targets, contains('61')); // Starting target
      expect(targets, contains('62')); // Second target
      expect(thrownPoints, contains('3')); // 3 points from first round
      expect(thrownPoints, contains('2')); // 2 points from second round
      expect(totalPoints, contains('5')); // Total 5 points
    });

    /// Tests CatchXX interface methods
    /// Verifies: interface methods work correctly
    testWidgets('CatchXX interface methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      // Test getInput method (not used in CatchXX)
      expect(controller.getInput(), equals(""));

      // Test isButtonDisabled method
      expect(controller.isButtonDisabled(1), isTrue); // Button 1 always disabled
      expect(controller.isButtonDisabled(2), isFalse); // Button 2 normally enabled
      expect(controller.isButtonDisabled(3), isFalse); // Button 3 always enabled

      // Test correctDarts method (not used in CatchXX, should not crash)
      controller.correctDarts(1); // Should do nothing

      // Test getStats method
      String stats = controller.getStats();
      expect(stats, contains('#S: 0')); // Number of games
      expect(stats, contains('♛C: 0')); // Record hits
      expect(stats, contains('♛P: 0')); // Record points
      expect(stats, contains('ØP: 0.0')); // Average points
    });

    /// Tests CatchXX game progression without completion
    /// Verifies: game can progress through many targets without triggering dialogs
    testWidgets('CatchXX game progression', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      testContext = tester.element(find.byType(ViewCatchXX));

      // Act: Play through many targets (but not to 100 to avoid dialog)
      for (int i = 0; i < 30; i++) {
        controller.pressNumpadButton(testContext, 2 + (i % 4)); // Varying darts (2-5)
        await tester.pump();
      }

      // Assert: Game progressed correctly
      expect(controller.target, equals(91)); // Should be at target 91 (61 + 30)
      expect(controller.round, equals(31)); // Should be at round 31
      expect(controller.hits, equals(30)); // 30 hits recorded
      expect(controller.points, greaterThan(0)); // Some points recorded
      
      // Assert: No dialogs appeared (game not completed)
      expect(find.byType(Dialog), findsNothing);
    });

    /// Tests CatchXX statistics with existing data
    /// Verifies: statistics are read correctly from storage
    testWidgets('CatchXX statistics with existing data', (WidgetTester tester) async {
      disableOverflowError();
      
      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(4);
      when(mockStorage.read('recordHits')).thenReturn(35);
      when(mockStorage.read('recordPoints')).thenReturn(78);
      when(mockStorage.read('longtermPoints')).thenReturn(18.5);

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerCatchXX>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewCatchXX(title: 'CatchXX Test'),
          ),
        ),
      );

      // Assert: Verify stats string with existing data
      String stats = controller.getStats();
      expect(stats, contains('#S: 4')); // Number of games
      expect(stats, contains('♛C: 35')); // Record hits
      expect(stats, contains('♛P: 78')); // Record points
      expect(stats, contains('ØP: 18.5')); // Average points
    });
  });
}
