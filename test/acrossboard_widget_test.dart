import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_acrossboard.dart';
import 'package:dart/view/view_acrossboard.dart';
import 'package:dart/widget/menu.dart';

import 'acrossboard_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('Across Board Game Widget Tests', () {
    late ControllerAcrossBoard controller;
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
      controller = ControllerAcrossBoard.forTesting(mockStorage);

      // Initialize with a proper MenuItem
      controller.init(MenuItem(
        id: 'test_acrossboard',
        name: 'Across Board Test',
        view: const ViewAcrossBoard(title: 'Across Board Test'),
        getController: (_) => controller,
        params: {'max': 20},
      ));
    });

    /// Tests basic Across Board game initialization
    /// Verifies: target sequence creation, initial state
    testWidgets('Across Board game initialization', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Assert: Initial game state
      expect(controller.getCurrentTargetIndex(), equals(0));
      expect(controller.round, equals(1));
      expect(controller.dart, equals(0));
      expect(controller.finished, equals(false));
      
      // Assert: Target sequence has 11 targets
      expect(controller.getTargetSequence().length, equals(11));
      expect(controller.getTargetsHit().length, equals(11));
      
      // Assert: All targets initially not hit
      expect(controller.getTargetsHit().every((hit) => !hit), equals(true));
    });

    /// Tests target progression and hit tracking
    /// Verifies: targets are marked as hit, progression works correctly
    testWidgets('Across Board target progression', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Act: Hit 2 targets in first round
      controller.pressNumpadButton(2);
      await tester.pump();

      // Assert: 2 targets hit, progression correct
      expect(controller.getCurrentTargetIndex(), equals(2));
      expect(controller.getTargetsHit()[0], equals(true));
      expect(controller.getTargetsHit()[1], equals(true));
      expect(controller.getTargetsHit()[2], equals(false));
      expect(controller.round, equals(2));
      expect(controller.dart, equals(3));

      // Act: Hit 1 more target
      controller.pressNumpadButton(1);
      await tester.pump();

      // Assert: 3 targets total hit
      expect(controller.getCurrentTargetIndex(), equals(3));
      expect(controller.getTargetsHit()[2], equals(true));
      expect(controller.round, equals(3));
      expect(controller.dart, equals(6));
    });

    /// Tests undo functionality
    /// Verifies: undo reverts last round correctly, including 0-hit rounds
    testWidgets('Across Board undo functionality', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Act: Hit 1 target, then 0 targets
      controller.pressNumpadButton(1);
      await tester.pump();
      controller.pressNumpadButton(0); // 0 hits round
      await tester.pump();

      // Assert: State after 0-hit round
      expect(controller.getCurrentTargetIndex(), equals(1));
      expect(controller.round, equals(3));
      expect(controller.dart, equals(6));

      // Act: Undo the 0-hit round
      controller.pressNumpadButton(-2);
      await tester.pump();

      // Assert: Back to state after 1 hit
      expect(controller.getCurrentTargetIndex(), equals(1));
      expect(controller.round, equals(2));
      expect(controller.dart, equals(3));
      expect(controller.getTargetsHit()[0], equals(true));
    });

    /// Tests input validation
    /// Verifies: buttons disabled when fewer targets remain
    testWidgets('Across Board input validation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Act: Hit 10 targets (only 1 remaining)
      for (int i = 0; i < 5; i++) {
        controller.pressNumpadButton(2);
        await tester.pump();
      }

      // Assert: Only 1 target remaining
      expect(controller.getCurrentTargetIndex(), equals(10));
      
      // Assert: Button validation
      expect(controller.isButtonDisabled(1), equals(false)); // 1 hit allowed
      expect(controller.isButtonDisabled(2), equals(true));  // 2 hits disabled
      expect(controller.isButtonDisabled(3), equals(true));  // 3 hits disabled
    });

    /// Tests game completion and statistics
    /// Verifies: game ends correctly, stats calculated properly
    testWidgets('Across Board game completion', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Act: Complete the game (hit all 11 targets)
      // Hit 3 targets per round for 3 rounds, then 2 targets
      for (int i = 0; i < 3; i++) {
        controller.pressNumpadButton(3);
        await tester.pump();
      }
      
      // Before final round, verify we're at target 9
      expect(controller.getCurrentTargetIndex(), equals(9));
      
      controller.pressNumpadButton(2); // Final 2 targets
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert: Game completed
      expect(controller.finished, equals(true));
      expect(controller.getCurrentTargetIndex(), equals(11));
      
      // Assert: All targets hit
      expect(controller.getTargetsHit().every((hit) => hit), equals(true));
      
      // Assert: Statistics
      expect(controller.dart, equals(12)); // 4 rounds * 3 darts
      Map stats = controller.getCurrentStats();
      expect(stats['darts'], equals(12));
      expect(double.parse(stats['avgChecks']), closeTo(1.09, 0.02)); // 12/11 ≈ 1.09
    });

    /// Tests summary creation
    /// Verifies: summary lines are created correctly
    testWidgets('Across Board summary creation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Act: Play some rounds
      controller.pressNumpadButton(2);
      controller.pressNumpadButton(1);
      await tester.pump();

      // Act: Create summary
      var summaryLines = controller.createSummaryLines();

      // Assert: Summary contains expected lines
      expect(summaryLines.length, equals(2));
      expect(summaryLines[0].label, equals('Anzahl Darts'));
      expect(summaryLines[0].value, equals('6'));
      expect(summaryLines[1].label, equals('Darts/Target'));
      expect(summaryLines[1].emphasized, equals(true));
    });

    /// Tests statistics calculation accuracy
    /// Verifies: darts per target calculation is correct in various scenarios
    testWidgets('Across Board statistics calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerAcrossBoard>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewAcrossBoard(title: 'Across Board Test'),
          ),
        ),
      );

      // Test 1: Initial state (0 targets hit)
      Map stats = controller.getCurrentStats();
      expect(stats['darts'], equals(0));
      expect(stats['avgChecks'], equals('0.0'));

      // Test 2: After hitting 1 target in 1 round
      controller.pressNumpadButton(1);
      await tester.pump();
      
      stats = controller.getCurrentStats();
      expect(stats['darts'], equals(3));
      expect(stats['avgChecks'], equals('3.0')); // 3 darts / 1 target = 3.0

      // Test 3: After hitting 2 more targets in next round (3 total)
      controller.pressNumpadButton(2);
      await tester.pump();
      
      stats = controller.getCurrentStats();
      expect(stats['darts'], equals(6));
      expect(stats['avgChecks'], equals('2.0')); // 6 darts / 3 targets = 2.0

      // Test 4: After a 0-hit round (still 3 targets)
      controller.pressNumpadButton(0);
      await tester.pump();
      
      stats = controller.getCurrentStats();
      expect(stats['darts'], equals(9));
      expect(stats['avgChecks'], equals('3.0')); // 9 darts / 3 targets = 3.0

      // Test 5: Hit 3 more targets (6 total)
      controller.pressNumpadButton(3);
      await tester.pump();
      
      stats = controller.getCurrentStats();
      expect(stats['darts'], equals(12));
      expect(stats['avgChecks'], equals('2.0')); // 12 darts / 6 targets = 2.0

      // Test 6: Verify round counting
      expect(stats['throw'], equals(5)); // 5 rounds played
    });

    /// Tests opposite number mapping
    /// Verifies: correct opposite numbers are used
    testWidgets('Across Board opposite number mapping', (WidgetTester tester) async {
      disableOverflowError();

      // Test multiple initializations to check different start numbers
      for (int i = 0; i < 10; i++) {
        controller.init(MenuItem(
          id: 'test_acrossboard',
          name: 'Across Board Test',
          view: const ViewAcrossBoard(title: 'Across Board Test'),
          getController: (_) => controller,
          params: {'max': 20},
        ));

        int startNumber = controller.getStartNumber();
        int oppositeNumber = controller.getOppositeNumber();
        
        // Assert: Valid start number
        expect(startNumber, greaterThanOrEqualTo(1));
        expect(startNumber, lessThanOrEqualTo(20));
        
        // Assert: Correct opposite mapping (spot check a few known pairs)
        if (startNumber == 20) expect(oppositeNumber, equals(3));
        if (startNumber == 3) expect(oppositeNumber, equals(20));
        if (startNumber == 19) expect(oppositeNumber, equals(1));
        if (startNumber == 2) expect(oppositeNumber, equals(12));
        
        // Assert: Target sequence structure
        List<String> targets = controller.getTargetSequence();
        expect(targets[0], equals('D$startNumber'));
        expect(targets[4], equals('SB'));
        expect(targets[5], equals('DB'));
        expect(targets[6], equals('SB'));
        expect(targets[10], equals('D$oppositeNumber'));
      }
    });
  });
}
