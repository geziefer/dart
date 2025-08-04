import 'package:flutter_test/flutter_test.dart';
import 'package:dart/utils/stats_formatter.dart';

void main() {
  group('StatsFormatter Tests', () {
    
    /// Tests StatsFormatter constants
    /// Verifies: All symbols are defined correctly
    test('StatsFormatter constants', () {
      expect(StatsFormatter.gamesSymbol, equals('#S'));
      expect(StatsFormatter.recordSymbol, equals('♛'));
      expect(StatsFormatter.averageSymbol, equals('Ø'));
    });

    /// Tests formatGameStats with various data types
    /// Verifies: Complete stats string formatting works correctly
    test('formatGameStats comprehensive test', () {
      // Test with mixed data types
      final result = StatsFormatter.formatGameStats(
        numberGames: 10,
        records: {
          'P': 150,           // int
          'D': 12.5,          // double
          'C': 8,             // int
        },
        averages: {
          'P': 85.7,          // double
          'D': 18.0,          // double with .0
          'T': 25,            // int
        },
      );

      expect(result, contains('#S: 10'));
      expect(result, contains('♛P: 150'));
      expect(result, contains('♛D: 12.5'));
      expect(result, contains('♛C: 8'));
      expect(result, contains('ØP: 85.7'));
      expect(result, contains('ØD: 18.0'));
      expect(result, contains('ØT: 25'));
      
      // Verify parts are separated by double spaces
      expect(result.split('  ').length, equals(7));
    });

    /// Tests formatGameStats with empty maps
    /// Verifies: Handles empty records and averages gracefully
    test('formatGameStats with empty maps', () {
      final result = StatsFormatter.formatGameStats(
        numberGames: 5,
        records: {},
        averages: {},
      );

      expect(result, equals('#S: 5'));
    });

    /// Tests formatGameStats with zero games
    /// Verifies: Handles zero games correctly
    test('formatGameStats with zero games', () {
      final result = StatsFormatter.formatGameStats(
        numberGames: 0,
        records: {'P': 0},
        averages: {'P': 0.0},
      );

      expect(result, equals('#S: 0  ♛P: 0  ØP: 0.0'));
    });

    /// Tests formatStat method
    /// Verifies: Individual stat formatting works correctly
    test('formatStat method', () {
      expect(StatsFormatter.formatStat('♛', 'P', 150), equals('♛P: 150'));
      expect(StatsFormatter.formatStat('Ø', 'D', 12.5), equals('ØD: 12.5'));
      expect(StatsFormatter.formatStat('#', 'S', 10), equals('#S: 10'));
    });

    /// Tests formatRecord method
    /// Verifies: Record formatting uses correct symbol
    test('formatRecord method', () {
      expect(StatsFormatter.formatRecord('P', 180), equals('♛P: 180'));
      expect(StatsFormatter.formatRecord('D', 9.5), equals('♛D: 9.5'));
      expect(StatsFormatter.formatRecord('C', 0), equals('♛C: 0'));
    });

    /// Tests formatAverage method
    /// Verifies: Average formatting uses correct symbol
    test('formatAverage method', () {
      expect(StatsFormatter.formatAverage('P', 85.7), equals('ØP: 85.7'));
      expect(StatsFormatter.formatAverage('D', 18.0), equals('ØD: 18.0'));
      expect(StatsFormatter.formatAverage('T', 25), equals('ØT: 25'));
    });

    /// Tests formatGamesCount method
    /// Verifies: Games count formatting works correctly
    test('formatGamesCount method', () {
      expect(StatsFormatter.formatGamesCount(0), equals('#S: 0'));
      expect(StatsFormatter.formatGamesCount(1), equals('#S: 1'));
      expect(StatsFormatter.formatGamesCount(100), equals('#S: 100'));
      expect(StatsFormatter.formatGamesCount(9999), equals('#S: 9999'));
    });

    /// Tests _formatValue method indirectly through public methods
    /// Verifies: Value formatting handles different data types correctly
    test('value formatting through public methods', () {
      // Test integer formatting
      expect(StatsFormatter.formatStat('♛', 'P', 150), contains('150'));
      expect(StatsFormatter.formatStat('♛', 'P', 0), contains('0'));
      expect(StatsFormatter.formatStat('♛', 'P', -5), contains('-5'));

      // Test double formatting
      expect(StatsFormatter.formatStat('Ø', 'P', 85.7), contains('85.7'));
      expect(StatsFormatter.formatStat('Ø', 'P', 18.0), contains('18.0'));
      expect(StatsFormatter.formatStat('Ø', 'P', 0.0), contains('0.0'));
      expect(StatsFormatter.formatStat('Ø', 'P', 123.456), contains('123.5')); // Should round to 1 decimal

      // Test string formatting
      expect(StatsFormatter.formatStat('♛', 'P', 'test'), contains('test'));
    });

    /// Tests createStatsMap method
    /// Verifies: Stats map creation works correctly
    test('createStatsMap comprehensive test', () {
      final statsMap = StatsFormatter.createStatsMap(
        games: 15,
        records: {
          'P': 180,
          'D': 9.5,
          'C': 12,
        },
        averages: {
          'P': 85.7,
          'D': 18.0,
          'T': 25,
        },
      );

      // Verify games entry
      expect(statsMap['games'], equals('#S: 15'));

      // Verify record entries
      expect(statsMap['record_P'], equals('♛P: 180'));
      expect(statsMap['record_D'], equals('♛D: 9.5'));
      expect(statsMap['record_C'], equals('♛C: 12'));

      // Verify average entries
      expect(statsMap['average_P'], equals('ØP: 85.7'));
      expect(statsMap['average_D'], equals('ØD: 18.0'));
      expect(statsMap['average_T'], equals('ØT: 25'));

      // Verify total entries
      expect(statsMap.length, equals(7)); // 1 games + 3 records + 3 averages
    });

    /// Tests createStatsMap with null parameters
    /// Verifies: Handles null records and averages gracefully
    test('createStatsMap with null parameters', () {
      final statsMap = StatsFormatter.createStatsMap(
        games: 5,
        records: null,
        averages: null,
      );

      expect(statsMap.length, equals(1));
      expect(statsMap['games'], equals('#S: 5'));
    });

    /// Tests createStatsMap with empty maps
    /// Verifies: Handles empty records and averages correctly
    test('createStatsMap with empty maps', () {
      final statsMap = StatsFormatter.createStatsMap(
        games: 3,
        records: {},
        averages: {},
      );

      expect(statsMap.length, equals(1));
      expect(statsMap['games'], equals('#S: 3'));
    });

    /// Tests edge cases and special values
    /// Verifies: Handles edge cases correctly
    test('edge cases and special values', () {
      // Test very large numbers
      expect(StatsFormatter.formatRecord('P', 999999), equals('♛P: 999999'));
      expect(StatsFormatter.formatAverage('P', 999.9), equals('ØP: 999.9'));

      // Test very small numbers
      expect(StatsFormatter.formatAverage('P', 0.1), equals('ØP: 0.1'));
      expect(StatsFormatter.formatAverage('P', 0.01), equals('ØP: 0.0')); // Rounds to 1 decimal

      // Test negative numbers
      expect(StatsFormatter.formatRecord('P', -10), equals('♛P: -10'));
      expect(StatsFormatter.formatAverage('P', -5.5), equals('ØP: -5.5'));
    });

    /// Tests decimal precision
    /// Verifies: Double values are formatted to exactly 1 decimal place
    test('decimal precision formatting', () {
      final testCases = [
        {'input': 85.0, 'expected': '85.0'},
        {'input': 85.1, 'expected': '85.1'},
        {'input': 85.12, 'expected': '85.1'},
        {'input': 85.15, 'expected': '85.2'}, // Rounds up
        {'input': 85.99, 'expected': '86.0'}, // Rounds up
        {'input': 0.0, 'expected': '0.0'},
        {'input': 0.05, 'expected': '0.1'}, // Rounds up
        {'input': 0.04, 'expected': '0.0'}, // Rounds down
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as double;
        final expected = testCase['expected'] as String;
        final result = StatsFormatter.formatAverage('P', input);
        expect(result, equals('ØP: $expected'), 
               reason: 'Input $input should format to $expected');
      }
    });

    /// Tests complex stats formatting scenario
    /// Verifies: Real-world usage scenario works correctly
    test('complex real-world scenario', () {
      // Simulate a dart game with various statistics
      final result = StatsFormatter.formatGameStats(
        numberGames: 25,
        records: {
          'P': 180,      // Record points
          'D': 9,        // Record darts
          'C': 15,       // Record checkouts
          'F': 170,      // Record finish
        },
        averages: {
          'P': 78.5,     // Average points
          'D': 15.2,     // Average darts
          'C': 8.7,      // Average checkouts
          'A': 92.3,     // Average accuracy
        },
      );

      // Verify all components are present
      expect(result, contains('#S: 25'));
      expect(result, contains('♛P: 180'));
      expect(result, contains('♛D: 9'));
      expect(result, contains('♛C: 15'));
      expect(result, contains('♛F: 170'));
      expect(result, contains('ØP: 78.5'));
      expect(result, contains('ØD: 15.2'));
      expect(result, contains('ØC: 8.7'));
      expect(result, contains('ØA: 92.3'));

      // Verify structure
      final parts = result.split('  ');
      expect(parts.length, equals(9)); // 1 games + 4 records + 4 averages
      expect(parts[0], equals('#S: 25')); // Games always first
    });
  });
}
