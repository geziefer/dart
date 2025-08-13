import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/view/view_shootx.dart';
import 'package:dart/widget/menu.dart';

import 'shootx_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('ShootX Game Widget Tests', () {
    late ControllerShootx controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      // Set up default mock responses (simulate fresh game stats)
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordNumbers')).thenReturn(0);
      when(mockStorage.read('longtermNumbers')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      // Create controller with injected mock storage
      controller = ControllerShootx.forTesting(mockStorage);

      // Initialize with safe parameters (10 rounds max, target number 20)
      controller.init(MenuItem(
        id: 'test_shoot20',
        name: 'Shoot 20s Test',
        view: const ViewShootx(title: 'Shoot 20s Test'),
        getController: (_) => controller,
        params: {'x': 20, 'max': 10}, // Target 20s, 10 rounds max
      ));
    });

    /// Tests ShootX widget creation and initial state
    /// Verifies: widget can be created and displays correctly
    testWidgets('ShootX widget creation and initial state',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Assert: Widget was created successfully
      expect(find.byType(ViewShootx), findsOneWidget);
      expect(find.text('Shoot 20s Test'), findsOneWidget);

      // Assert: Initial controller state
      expect(controller.number, equals(0)); // No hits yet
      expect(controller.round, equals(1)); // First round
      expect(controller.rounds.isEmpty, isTrue);
      expect(controller.thrownNumbers.isEmpty, isTrue);
      expect(controller.totalNumbers.isEmpty, isTrue);
    });

    /// Tests ShootX basic scoring functionality
    /// Verifies: hits are recorded correctly, totals are calculated
    testWidgets('ShootX basic scoring functionality',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Record some hits in first round
      controller.pressNumpadButton(3); // 3 hits
      await tester.pump();

      // Assert: First round recorded correctly
      expect(controller.number, equals(3)); // Total hits
      expect(controller.round, equals(2)); // Advanced to round 2
      expect(controller.rounds.length, equals(1));
      expect(controller.thrownNumbers[0], equals(3)); // 3 hits in round 1
      expect(controller.totalNumbers[0], equals(3)); // Running total

      // Act: Record hits in second round
      controller.pressNumpadButton(2); // 2 more hits
      await tester.pump();

      // Assert: Second round recorded correctly
      expect(controller.number, equals(5)); // Total hits (3+2)
      expect(controller.round, equals(3)); // Advanced to round 3
      expect(controller.rounds.length, equals(2));
      expect(controller.thrownNumbers[1], equals(2)); // 2 hits in round 2
      expect(controller.totalNumbers[1], equals(5)); // Running total
    });

    /// Tests ShootX return button (0 hits) functionality
    /// Verifies: return button records 0 hits correctly
    testWidgets('ShootX return button functionality',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Use return button (should record 0 hits)
      controller.pressNumpadButton(-1); // Return button
      await tester.pump();

      // Assert: Return button recorded 0 hits
      expect(controller.number, equals(0)); // No hits added
      expect(controller.round, equals(2)); // Round advanced
      expect(controller.thrownNumbers[0], equals(0)); // 0 hits recorded
      expect(controller.totalNumbers[0], equals(0)); // Running total
    });

    /// Tests ShootX undo functionality
    /// Verifies: undo removes last round, restores previous state
    testWidgets('ShootX undo functionality', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Play a few rounds
      controller.pressNumpadButton(4); // 4 hits
      await tester.pump();
      controller.pressNumpadButton(2); // 2 hits
      await tester.pump();

      // Assert: Verify state before undo
      expect(controller.number, equals(6)); // 4 + 2
      expect(controller.round, equals(3));
      expect(controller.rounds.length, equals(2));

      // Act: Undo last round
      controller.pressNumpadButton(-2); // Undo button
      await tester.pump();

      // Assert: Verify undo worked
      expect(controller.number, equals(4)); // Back to 4 hits
      expect(controller.round, equals(2)); // Back to round 2
      expect(controller.rounds.length, equals(1)); // One round removed
      expect(controller.thrownNumbers.length, equals(1));
      expect(controller.totalNumbers.length, equals(1));
    });

    /// Tests ShootX undo edge cases
    /// Verifies: undo doesn't work when no rounds played
    testWidgets('ShootX undo edge cases', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Try to undo when no rounds have been played
      controller.pressNumpadButton(-2); // Undo button
      await tester.pump();

      // Assert: Undo had no effect (no rounds to undo)
      expect(controller.number, equals(0));
      expect(controller.round, equals(1));
      expect(controller.rounds.isEmpty, isTrue);
    });

    /// Tests ShootX statistics calculation
    /// Verifies: statistics are calculated correctly during gameplay
    testWidgets('ShootX statistics calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Play a few rounds
      controller.pressNumpadButton(6); // 6 hits in round 1
      await tester.pump();
      controller.pressNumpadButton(4); // 4 hits in round 2
      await tester.pump();

      // Assert: Verify statistics calculation
      Map stats = controller.getCurrentStats();
      expect(stats['round'], equals(3)); // Current round
      expect(stats['hits'], equals(10)); // Total hits (6+4) - Fixed key name
      expect(stats['avgHits'],
          equals('5.0')); // 10 hits / 2 rounds = 5.0 - Fixed key name

      // Act: Play one more round
      controller.pressNumpadButton(2); // 2 hits in round 3
      await tester.pump();

      // Assert: Verify updated statistics
      stats = controller.getCurrentStats();
      expect(stats['round'], equals(4)); // Current round
      expect(stats['hits'], equals(12)); // Total hits (6+4+2) - Fixed key name
      expect(stats['avgHits'],
          equals('4.0')); // 12 hits / 3 rounds = 4.0 - Fixed key name
    });

    /// Tests ShootX string generation methods
    /// Verifies: string methods return properly formatted data
    testWidgets('ShootX string generation methods',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Play a few rounds to generate data
      controller.pressNumpadButton(3); // Round 1: 3 hits
      controller.pressNumpadButton(1); // Round 2: 1 hit
      await tester.pump();

      // Assert: String methods return valid data
      expect(controller.getCurrentRounds(), isA<String>());
      expect(controller.getCurrentThrownNumbers(), isA<String>());
      expect(controller.getCurrentTotalNumbers(), isA<String>());

      // Assert: String methods contain expected data patterns
      String rounds = controller.getCurrentRounds();
      String thrownNumbers = controller.getCurrentThrownNumbers();
      String totalNumbers = controller.getCurrentTotalNumbers();

      expect(rounds, contains('1')); // Round 1
      expect(rounds, contains('2')); // Round 2
      expect(thrownNumbers, contains('3')); // 3 hits
      expect(thrownNumbers, contains('1')); // 1 hit
      expect(totalNumbers, contains('4')); // Total 4 hits
    });

    /// Tests ShootX interface methods
    /// Verifies: interface methods work correctly
    testWidgets('ShootX interface methods', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Test getInput method (not used in ShootX)
      expect(controller.getInput(), equals(""));

      // Test isButtonDisabled method
      expect(controller.isButtonDisabled(5), isFalse); // No buttons disabled

      // Test correctDarts method (not used in ShootX, should not crash)
      controller.correctDarts(1); // Should do nothing

      // Test getStats method
      String stats = controller.getStats();
      expect(stats, contains('#S: 0')); // Number of games
      expect(stats, contains('♛T: 0')); // Record numbers (Treffer)
      expect(stats, contains('ØT: 0')); // Average hits (Treffer)
    });

    /// Tests ShootX game progression without completion
    /// Verifies: game can progress through multiple rounds without triggering dialogs
    testWidgets('ShootX game progression', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Act: Play through several rounds (but not all 10 to avoid dialog)
      for (int i = 1; i <= 8; i++) {
        controller.pressNumpadButton(i % 4); // Varying hits
        await tester.pump();
      }

      // Assert: Game progressed correctly
      expect(controller.round, equals(9)); // Should be at round 9
      expect(controller.rounds.length, equals(8)); // 8 rounds played
      expect(controller.number, greaterThan(0)); // Some hits recorded

      // Assert: No dialogs appeared (game not completed)
      expect(find.byType(Dialog), findsNothing);
    });

    /// Tests ShootX statistics with existing data
    /// Verifies: statistics are read correctly from storage
    testWidgets('ShootX statistics with existing data',
        (WidgetTester tester) async {
      disableOverflowError();

      // Arrange: Mock existing game statistics
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('recordNumbers')).thenReturn(25);
      when(mockStorage.read('longtermHits')).thenReturn(4.2); // Fixed key name

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerShootx>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewShootx(title: 'Shoot 20s Test'),
          ),
        ),
      );

      // Assert: Verify stats string with existing data
      String stats = controller.getStats();
      expect(stats, contains('#S: 5')); // Number of games
      expect(stats, contains('♛T: 25')); // Record numbers (Treffer)
      expect(stats, contains('ØT: 4.2')); // Average hits (Treffer)
    });
  });
}
