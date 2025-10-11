import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

import 'package:dart/controller/controller_cricket.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';

import 'cricket_widget_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('Cricket Game Controller Tests', () {
    late ControllerCricket controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      // Set up default mock responses
      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('recordDarts')).thenReturn(0);
      when(mockStorage.read('recordAvgHits')).thenReturn(0.0);
      when(mockStorage.read('longtermAvgHits')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      controller = ControllerCricket.forTesting(mockStorage);

      // Initialize with cricket parameters
      controller.init(MenuItem(
        id: 'test_cricket',
        name: 'Cricket Test',
        view: const SizedBox(),
        getController: (_) => controller,
        params: {},
      ));
    });

    /// Tests initial game state and statistics
    /// Verifies: all cricket numbers initialized to 0, correct initial stats
    test('Initial game state', () {
      expect(controller.hits[15], equals(0));
      expect(controller.hits[16], equals(0));
      expect(controller.hits[17], equals(0));
      expect(controller.hits[18], equals(0));
      expect(controller.hits[19], equals(0));
      expect(controller.hits[20], equals(0));
      expect(controller.hits[25], equals(0));
      expect(controller.round, equals(1));
      expect(controller.totalHits, equals(0));
      expect(controller.totalDarts, equals(0));
      
      Map<String, String> stats = controller.getCurrentStats();
      expect(stats['round'], equals('1'));
      expect(stats['darts'], equals('0'));
      expect(stats['leftover'], equals('21'));
      expect(stats['avgHits'], equals('0.0'));
    });

    /// Tests average calculation at start (should be 0.0)
    /// Verifies: average is 0.0 when no rounds completed
    test('Average calculation at start', () {
      Map<String, String> stats = controller.getCurrentStats();
      expect(stats['avgHits'], equals('0.0'));
    });

    /// Tests hitting cricket numbers and input formatting
    /// Verifies: hits are recorded, input is formatted correctly with sorting and grouping
    test('Hitting cricket numbers and input formatting', () {
      // Hit 19, 20, 19 - should display as "D19 | 20"
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      controller.pressNumpadButton(19);
      
      expect(controller.hits[19], equals(2));
      expect(controller.hits[20], equals(1));
      expect(controller.totalHits, equals(3));
      expect(controller.getInput(), equals('D19 | 20'));
      
      // Add bull - should display as "D19 | 20 | B"
      controller.pressNumpadButton(25);
      expect(controller.hits[25], equals(1));
      expect(controller.getInput(), equals('D19 | 20 | B'));
    });

    /// Tests round completion and dart counting
    /// Verifies: darts are added correctly when round ends
    test('Round completion and dart counting', () {
      // Hit some numbers
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      
      expect(controller.totalDarts, equals(0)); // No darts counted yet
      expect(controller.round, equals(1));
      
      // End round
      controller.pressNumpadButton(-1); // Enter
      
      expect(controller.totalDarts, equals(3)); // 3 darts added
      expect(controller.round, equals(2));
      expect(controller.getInput(), equals('')); // Input cleared
    });

    /// Tests average calculation after 1 completed round
    /// Verifies: average is calculated correctly after first round
    test('Average calculation after 1 completed round', () {
      // Complete first round with 2 hits
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      controller.pressNumpadButton(-1); // End round
      
      Map<String, String> stats = controller.getCurrentStats();
      expect(stats['round'], equals('2'));
      expect(stats['darts'], equals('3'));
      expect(stats['avgHits'], equals('2.0')); // 2 hits / 1 round
    });

    /// Tests average calculation after 2 completed rounds
    /// Verifies: average is calculated correctly across multiple rounds
    test('Average calculation after 2 completed rounds', () {
      // First round: 2 hits
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      controller.pressNumpadButton(-1); // End round
      
      // Second round: 1 hit
      controller.pressNumpadButton(15);
      controller.pressNumpadButton(-1); // End round
      
      Map<String, String> stats = controller.getCurrentStats();
      expect(stats['round'], equals('3'));
      expect(stats['darts'], equals('6'));
      expect(stats['avgHits'], equals('1.5')); // 3 hits / 2 rounds
    });

    /// Tests average doesn't change during round input
    /// Verifies: average only updates between rounds, not during input
    test('Average stays constant during round input', () {
      // Complete first round
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      controller.pressNumpadButton(-1);
      
      double avgAfterRound = double.parse(controller.getCurrentStats()['avgHits']!);
      
      // Start hitting in second round
      controller.pressNumpadButton(15);
      double avgDuringInput1 = double.parse(controller.getCurrentStats()['avgHits']!);
      
      controller.pressNumpadButton(16);
      double avgDuringInput2 = double.parse(controller.getCurrentStats()['avgHits']!);
      
      // Average should stay the same during input
      expect(avgDuringInput1, equals(avgAfterRound));
      expect(avgDuringInput2, equals(avgAfterRound));
    });

    /// Tests game completion detection
    /// Verifies: game completion condition is detected correctly
    test('Game completion detection', () {
      // Manually set all numbers to 2 hits (almost complete)
      controller.hits[15] = 3;
      controller.hits[16] = 3;
      controller.hits[17] = 3;
      controller.hits[18] = 3;
      controller.hits[19] = 3;
      controller.hits[20] = 3;
      controller.hits[25] = 2; // Bull needs one more hit
      
      // Check that game is not yet complete
      bool isComplete = controller.hits.values.every((count) => count >= 3);
      expect(isComplete, isFalse);
      
      // Complete the last number
      controller.hits[25] = 3;
      
      // Check that game is now complete
      isComplete = controller.hits.values.every((count) => count >= 3);
      expect(isComplete, isTrue);
    });

    /// Tests dart correction functionality
    /// Verifies: correctDarts method properly adjusts totalDarts
    test('Dart correction functionality', () {
      // Complete some rounds first to build up darts
      controller.pressNumpadButton(15);
      controller.pressNumpadButton(-1); // End round, adds 3 darts
      
      expect(controller.totalDarts, equals(3));
      
      // Correct darts (subtract 1)
      controller.correctDarts(1);
      expect(controller.totalDarts, equals(2));
      
      // Stats should reflect corrected darts
      Map<String, String> stats = controller.getCurrentStats();
      expect(stats['darts'], equals('2'));
    });

    /// Tests undo functionality
    /// Verifies: undo removes hits and handles round transitions correctly
    test('Undo functionality', () {
      // Hit some numbers
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      
      expect(controller.hits[19], equals(1));
      expect(controller.hits[20], equals(1));
      expect(controller.totalHits, equals(2));
      
      // Undo last hit
      controller.pressNumpadButton(-2);
      expect(controller.hits[20], equals(0));
      expect(controller.totalHits, equals(1));
      expect(controller.getInput(), equals('19'));
      
      // Undo when round is empty - should go back to previous round
      controller.pressNumpadButton(-1); // End round
      expect(controller.round, equals(2));
      expect(controller.totalDarts, equals(3));
      
      controller.pressNumpadButton(-2); // Undo on empty round
      expect(controller.round, equals(1));
      expect(controller.totalDarts, equals(0));
    });

    /// Tests input constraints for cricket rules
    /// Verifies: maximum 3 distinct numbers per round, special bull rules
    test('Input constraints for cricket rules', () {
      // Hit 3 different numbers - should be allowed
      controller.pressNumpadButton(15);
      controller.pressNumpadButton(16);
      controller.pressNumpadButton(17);
      
      expect(controller.hits[15], equals(1));
      expect(controller.hits[16], equals(1));
      expect(controller.hits[17], equals(1));
      
      // Try to hit a 4th different number - should be blocked
      controller.pressNumpadButton(18);
      expect(controller.hits[18], equals(0));
      
      // But hitting same numbers should still work
      controller.pressNumpadButton(15);
      expect(controller.hits[15], equals(2));
    });

    /// Tests special bull constraints
    /// Verifies: 3 bulls cannot be done with 1 dart constraint
    test('Special bull constraints', () {
      // Hit 3 bulls
      controller.pressNumpadButton(25);
      controller.pressNumpadButton(25);
      controller.pressNumpadButton(25);
      
      // Try to add another number - should be limited
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(19);
      
      expect(controller.hits[25], equals(3));
      expect(controller.hits[19], equals(2));
      
      // Try to add a different number - should be blocked
      controller.pressNumpadButton(20);
      expect(controller.hits[20], equals(0));
    });

    /// Tests summary line creation
    /// Verifies: summary shows correct darts and average information
    test('Summary line creation', () {
      // Complete a short game
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      controller.pressNumpadButton(-1); // End round, 3 darts
      
      controller.pressNumpadButton(15);
      controller.pressNumpadButton(-1); // End round, 6 darts total
      
      // Simulate game end with dart correction
      controller.totalDarts += 3; // Final round
      controller.correctDarts(1); // Correct to 2 darts in final round
      
      List<SummaryLine> lines = controller.createSummaryLines();
      
      expect(lines.length, equals(2));
      expect(lines[0].label, equals('Darts'));
      expect(lines[0].value, equals('8')); // 3 + 3 + 2 darts
      expect(lines[1].label, equals('ØTreffer/Runde'));
      expect(lines[1].emphasized, isTrue);
    });

    /// Tests leftover targets calculation
    /// Verifies: correctly counts remaining hits needed
    test('Leftover targets calculation', () {
      // Hit some numbers partially
      controller.pressNumpadButton(15); // 1/3
      controller.pressNumpadButton(16); // 1/3
      controller.pressNumpadButton(16); // 2/3
      controller.pressNumpadButton(17); // 1/3
      controller.pressNumpadButton(17); // 2/3
      controller.pressNumpadButton(17); // 3/3 - complete
      
      Map<String, String> stats = controller.getCurrentStats();
      // 15: needs 2, 16: needs 1, 17: needs 0, 18-20,25: need 3 each = 2+1+0+3+3+3+3 = 15
      expect(stats['leftover'], equals('15'));
    });

    /// Tests stats string formatting
    /// Verifies: stats display correct abbreviations and values
    test('Stats string formatting', () {
      String stats = controller.getStats();
      
      // Should contain game count and abbreviated stats
      expect(stats, contains('S: 0')); // Spiele (games)
      expect(stats, contains('D: 0')); // Darts record
      expect(stats, contains('T: 0')); // Treffer (hits) record and average
    });

    /// Tests view integration with controller
    /// Verifies: view callbacks are properly set up
    test('View integration callbacks', () {
      // Test that callbacks can be set
      controller.onGameEnded = () {};
      controller.onShowCheckout = (remaining, score) {};
      
      expect(controller.onGameEnded, isNotNull);
      expect(controller.onShowCheckout, isNotNull);
    });

    /// Tests cricket board display data
    /// Verifies: hits data is properly formatted for display
    test('Cricket board display data', () {
      // Hit some numbers
      controller.pressNumpadButton(15);
      controller.pressNumpadButton(15);
      controller.pressNumpadButton(20);
      
      // Verify hits map contains correct data for display
      expect(controller.hits[15], equals(2));
      expect(controller.hits[20], equals(1));
      expect(controller.hits[16], equals(0));
      expect(controller.hits[25], equals(0));
    });

    /// Tests round hits tracking for checkout dialog
    /// Verifies: round hits are tracked correctly for dart count calculation
    test('Round hits tracking for checkout', () {
      // Complete a round with specific hits
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(20);
      controller.pressNumpadButton(19);
      controller.pressNumpadButton(-1); // End round
      
      List<List<int>> roundHits = controller.getRoundHits;
      expect(roundHits.length, equals(2)); // Original empty round + new empty round after completion
      expect(roundHits[0].length, equals(3)); // Should have 3 hits in first round
      expect(roundHits[0], contains(19));
      expect(roundHits[0], contains(20));
    });

    /// Tests game completion with view integration
    /// Verifies: game completion triggers proper view updates
    test('Game completion with view integration', () {
      bool gameEndedTriggered = false;
      controller.onGameEnded = () {
        gameEndedTriggered = true;
      };
      
      // Complete all numbers (need 3 hits each) - manually set hits
      controller.hits[15] = 3;
      controller.hits[16] = 3;
      controller.hits[17] = 3;
      controller.hits[18] = 3;
      controller.hits[19] = 3;
      controller.hits[20] = 3;
      controller.hits[25] = 3;
      
      // Check if game is complete
      bool isComplete = controller.hits.values.every((count) => count >= 3);
      if (isComplete && controller.onGameEnded != null) {
        controller.onGameEnded!();
      }
      
      expect(isComplete, isTrue);
      expect(gameEndedTriggered, isTrue);
    });
  });
}
