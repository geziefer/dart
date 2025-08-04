import 'package:flutter_test/flutter_test.dart';
import 'package:dart/services/summary_service.dart';

void main() {
  group('SummaryService Tests', () {
    /// Tests createCompletionLine method
    /// Verifies: Completion lines are created correctly with proper symbols
    test('createCompletionLine method', () {
      // Test completed game
      final completedLine = SummaryService.createCompletionLine('501', true);
      expect(completedLine.label, equals('501 geschafft'));
      expect(completedLine.value, equals(''));
      expect(completedLine.checkSymbol, equals('✅'));
      expect(completedLine.emphasized, isFalse);

      // Test incomplete game
      final incompleteLine =
          SummaryService.createCompletionLine('Half It', false);
      expect(incompleteLine.label, equals('Half It geschafft'));
      expect(incompleteLine.value, equals(''));
      expect(incompleteLine.checkSymbol, equals('❌'));
      expect(incompleteLine.emphasized, isFalse);
    });

    /// Tests createValueLine method
    /// Verifies: Value lines are created correctly with different data types
    test('createValueLine method', () {
      // Test with integer
      final intLine = SummaryService.createValueLine('Punkte', 150);
      expect(intLine.label, equals('Punkte'));
      expect(intLine.value, equals('150'));
      expect(intLine.checkSymbol, isNull);
      expect(intLine.emphasized, isFalse);

      // Test with double
      final doubleLine = SummaryService.createValueLine('Average', 85.7);
      expect(doubleLine.label, equals('Average'));
      expect(doubleLine.value, equals('85.7'));
      expect(doubleLine.checkSymbol, isNull);
      expect(doubleLine.emphasized, isFalse);

      // Test with string
      final stringLine = SummaryService.createValueLine('Status', 'Complete');
      expect(stringLine.label, equals('Status'));
      expect(stringLine.value, equals('Complete'));
      expect(stringLine.checkSymbol, isNull);
      expect(stringLine.emphasized, isFalse);

      // Test with emphasized flag
      final emphasizedLine =
          SummaryService.createValueLine('Total', 500, emphasized: true);
      expect(emphasizedLine.label, equals('Total'));
      expect(emphasizedLine.value, equals('500'));
      expect(emphasizedLine.emphasized, isTrue);
    });

    /// Tests createAverageLine method
    /// Verifies: Average lines are created with proper decimal formatting
    test('createAverageLine method', () {
      // Test default decimals (1)
      final defaultLine = SummaryService.createAverageLine('ØPunkte', 85.7);
      expect(defaultLine.label, equals('ØPunkte'));
      expect(defaultLine.value, equals('85.7'));
      expect(defaultLine.emphasized, isTrue); // Default emphasized
      expect(defaultLine.checkSymbol, isNull);

      // Test custom decimals
      final customDecimalsLine =
          SummaryService.createAverageLine('Precision', 123.456, decimals: 2);
      expect(customDecimalsLine.label, equals('Precision'));
      expect(customDecimalsLine.value, equals('123.46'));
      expect(customDecimalsLine.emphasized, isTrue);

      // Test zero decimals
      final zeroDecimalsLine =
          SummaryService.createAverageLine('Rounded', 85.7, decimals: 0);
      expect(zeroDecimalsLine.label, equals('Rounded'));
      expect(zeroDecimalsLine.value, equals('86'));
      expect(zeroDecimalsLine.emphasized, isTrue);

      // Test not emphasized
      final notEmphasizedLine =
          SummaryService.createAverageLine('Normal', 50.5, emphasized: false);
      expect(notEmphasizedLine.label, equals('Normal'));
      expect(notEmphasizedLine.value, equals('50.5'));
      expect(notEmphasizedLine.emphasized, isFalse);
    });

    /// Tests createStandardSummaryLines method
    /// Verifies: Standard summary lines are created correctly
    test('createStandardSummaryLines comprehensive test', () {
      final lines = SummaryService.createStandardSummaryLines(
        gameName: '501 Checkout',
        gameCompleted: true,
        gameStats: {
          'Legs Won': 3,
          'Total Darts': 45,
          'Best Finish': 170,
          'Accuracy': 85.5,
        },
        averageLabel: 'ØDarts',
        averageValue: 15.2,
      );

      expect(lines.length, equals(6)); // 1 completion + 4 stats + 1 average

      // Check completion line
      expect(lines[0].label, equals('501 Checkout geschafft'));
      expect(lines[0].checkSymbol, equals('✅'));

      // Check game stats lines
      expect(lines[1].label, equals('Legs Won'));
      expect(lines[1].value, equals('3'));
      expect(lines[1].emphasized, isFalse);

      expect(lines[2].label, equals('Total Darts'));
      expect(lines[2].value, equals('45'));

      expect(lines[3].label, equals('Best Finish'));
      expect(lines[3].value, equals('170'));

      // Check double value is formatted as average line
      expect(lines[4].label, equals('Accuracy'));
      expect(lines[4].value, equals('85.5'));
      expect(
          lines[4].emphasized, isFalse); // Double values get emphasized: false

      // Check average line
      expect(lines[5].label, equals('ØDarts'));
      expect(lines[5].value, equals('15.2'));
      expect(lines[5].emphasized, isTrue);
    });

    /// Tests createStandardSummaryLines without average
    /// Verifies: Works correctly when no average is provided
    test('createStandardSummaryLines without average', () {
      final lines = SummaryService.createStandardSummaryLines(
        gameName: 'Half It',
        gameCompleted: false,
        gameStats: {
          'Score': 120,
          'Rounds': 7,
        },
      );

      expect(lines.length, equals(3)); // 1 completion + 2 stats

      // Check completion line
      expect(lines[0].label, equals('Half It geschafft'));
      expect(lines[0].checkSymbol, equals('❌'));

      // Check stats
      expect(lines[1].label, equals('Score'));
      expect(lines[1].value, equals('120'));

      expect(lines[2].label, equals('Rounds'));
      expect(lines[2].value, equals('7'));
    });

    /// Tests createStandardSummaryLines with empty stats
    /// Verifies: Handles empty game stats correctly
    test('createStandardSummaryLines with empty stats', () {
      final lines = SummaryService.createStandardSummaryLines(
        gameName: 'Empty Game',
        gameCompleted: true,
        gameStats: {},
        averageLabel: 'ØTest',
        averageValue: 42.0,
      );

      expect(lines.length, equals(2)); // 1 completion + 1 average

      expect(lines[0].label, equals('Empty Game geschafft'));
      expect(lines[0].checkSymbol, equals('✅'));

      expect(lines[1].label, equals('ØTest'));
      expect(lines[1].value, equals('42.0'));
    });

    /// Tests edge cases and special values
    /// Verifies: Handles edge cases correctly
    test('edge cases and special values', () {
      // Test with zero values
      final zeroLine = SummaryService.createValueLine('Zero', 0);
      expect(zeroLine.value, equals('0'));

      final zeroAverageLine = SummaryService.createAverageLine('Zero Avg', 0.0);
      expect(zeroAverageLine.value, equals('0.0'));

      // Test with negative values
      final negativeLine = SummaryService.createValueLine('Negative', -5);
      expect(negativeLine.value, equals('-5'));

      final negativeAverageLine =
          SummaryService.createAverageLine('Negative Avg', -2.5);
      expect(negativeAverageLine.value, equals('-2.5'));

      // Test with very large numbers
      final largeLine = SummaryService.createValueLine('Large', 999999);
      expect(largeLine.value, equals('999999'));

      // Test with very small decimals
      final smallDecimalLine =
          SummaryService.createAverageLine('Small', 0.001, decimals: 3);
      expect(smallDecimalLine.value, equals('0.001'));
    });

    /// Tests decimal precision in createAverageLine
    /// Verifies: Decimal formatting works correctly for various inputs
    test('createAverageLine decimal precision', () {
      final testCases = [
        {'input': 85.0, 'decimals': 1, 'expected': '85.0'},
        {'input': 85.12, 'decimals': 1, 'expected': '85.1'},
        {'input': 85.15, 'decimals': 1, 'expected': '85.2'},
        {'input': 85.99, 'decimals': 1, 'expected': '86.0'},
        {'input': 123.456, 'decimals': 2, 'expected': '123.46'},
        {'input': 123.456, 'decimals': 0, 'expected': '123'},
        {'input': 0.0, 'decimals': 1, 'expected': '0.0'},
        {'input': 0.05, 'decimals': 1, 'expected': '0.1'},
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as double;
        final decimals = testCase['decimals'] as int;
        final expected = testCase['expected'] as String;

        final line =
            SummaryService.createAverageLine('Test', input, decimals: decimals);
        expect(line.value, equals(expected),
            reason:
                'Input $input with $decimals decimals should format to $expected');
      }
    });

    /// Tests mixed data types in createStandardSummaryLines
    /// Verifies: Handles mixed int/double/string values correctly
    test('createStandardSummaryLines mixed data types', () {
      final lines = SummaryService.createStandardSummaryLines(
        gameName: 'Mixed Game',
        gameCompleted: true,
        gameStats: {
          'Integer Stat': 42,
          'Double Stat': 85.7,
          'String Stat': 'Excellent',
          'Zero Int': 0,
          'Zero Double': 0.0,
        },
      );

      expect(lines.length, equals(6)); // 1 completion + 5 stats

      // Check integer handling
      expect(lines[1].value, equals('42'));
      expect(lines[1].emphasized, isFalse);

      // Check double handling (should use createAverageLine)
      expect(lines[2].value, equals('85.7'));
      expect(lines[2].emphasized, isFalse);

      // Check string handling
      expect(lines[3].value, equals('Excellent'));
      expect(lines[3].emphasized, isFalse);

      // Check zero values
      expect(lines[4].value, equals('0'));
      expect(lines[5].value, equals('0.0'));
    });

    /// Tests German text in completion lines
    /// Verifies: German "geschafft" text is handled correctly
    test('German text handling', () {
      final testCases = [
        '501',
        'Half It',
        'Double Path',
        'Catch 40',
        'Speed Bull',
        'Bob\'s 27',
      ];

      for (final gameName in testCases) {
        final completedLine =
            SummaryService.createCompletionLine(gameName, true);
        expect(completedLine.label, equals('$gameName geschafft'));

        final incompleteLine =
            SummaryService.createCompletionLine(gameName, false);
        expect(incompleteLine.label, equals('$gameName geschafft'));
      }
    });

    /// Tests complex real-world scenario
    /// Verifies: Real-world usage scenario works correctly
    test('complex real-world dart game scenario', () {
      final lines = SummaryService.createStandardSummaryLines(
        gameName: '501 x 5',
        gameCompleted: true,
        gameStats: {
          'Legs Won': 5,
          'Total Throws': 87,
          'Best Checkout': 170,
          'Worst Checkout': 32,
          'Accuracy': 78.5,
          'First 9 Average': 85.2,
          'Doubles Hit': 12,
          'Doubles Missed': 8,
        },
        averageLabel: 'ØDarts per Leg',
        averageValue: 17.4,
      );

      expect(lines.length, equals(10)); // 1 completion + 8 stats + 1 average

      // Verify completion
      expect(lines[0].label, equals('501 x 5 geschafft'));
      expect(lines[0].checkSymbol, equals('✅'));

      // Verify all stats are present
      expect(lines.any((line) => line.label == 'Legs Won' && line.value == '5'),
          isTrue);
      expect(
          lines.any(
              (line) => line.label == 'Total Throws' && line.value == '87'),
          isTrue);
      expect(
          lines.any(
              (line) => line.label == 'Best Checkout' && line.value == '170'),
          isTrue);
      expect(
          lines.any((line) => line.label == 'Accuracy' && line.value == '78.5'),
          isTrue);
      expect(
          lines.any((line) =>
              line.label == 'First 9 Average' && line.value == '85.2'),
          isTrue);

      // Verify average line
      expect(lines.last.label, equals('ØDarts per Leg'));
      expect(lines.last.value, equals('17.4'));
      expect(lines.last.emphasized, isTrue);
    });
  });
}
