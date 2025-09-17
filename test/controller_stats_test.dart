import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/controller/controller_stats.dart';

void main() {
  group('Stats Controller Tests', () {
    late ControllerStats controller;

    setUp(() {
      controller = ControllerStats();
    });

    group('Export functionality', () {
      test('should generate valid JSON export data', () async {
        // Setup test data directly in controller
        controller.allStats.clear();
        controller.allStats['test_game'] = {
          'name': 'Test Game',
          'stats': {
            'numberGames': 5,
            'totalPoints': 100,
            'recordRoundPoints': 25,
          }
        };

        final exportData = await controller.exportStats();
        final parsed = jsonDecode(exportData);

        expect(parsed['version'], '1.0');
        expect(parsed['exportDate'], isNotNull);
        expect(parsed['games'], isNotNull);
        expect(parsed['games']['test_game']['name'], 'Test Game');
        expect(parsed['games']['test_game']['stats']['numberGames'], 5);
      });

      test('should handle empty stats export', () async {
        controller.allStats.clear();

        final exportData = await controller.exportStats();
        final parsed = jsonDecode(exportData);

        expect(parsed['version'], '1.0');
        expect(parsed['games'], isEmpty);
      });
    });

    group('Import validation', () {
      test('should validate correct import data format', () async {
        const validJson = '''
        {
          "version": "1.0",
          "exportDate": "2023-01-01T00:00:00.000Z",
          "games": {
            "test_game": {
              "name": "Test Game",
              "stats": {
                "numberGames": 5,
                "totalPoints": 100
              }
            }
          }
        }
        ''';

        final isValid = await controller.validateImportData(validJson);
        expect(isValid, isTrue);
      });

      test('should reject invalid JSON', () async {
        const invalidJson = 'not valid json';

        final isValid = await controller.validateImportData(invalidJson);
        expect(isValid, isFalse);
      });

      test('should reject data without version', () async {
        const invalidJson = '''
        {
          "games": {}
        }
        ''';

        final isValid = await controller.validateImportData(invalidJson);
        expect(isValid, isFalse);
      });

      test('should reject data without games', () async {
        const invalidJson = '''
        {
          "version": "1.0"
        }
        ''';

        final isValid = await controller.validateImportData(invalidJson);
        expect(isValid, isFalse);
      });
    });

    group('Data structure validation', () {
      test('should handle game data with proper structure', () {
        controller.allStats.clear();
        controller.allStats['game1'] = {
          'name': 'Game One',
          'stats': {
            'numberGames': 10,
            'totalPoints': 200,
            'recordRoundPoints': 50,
          }
        };

        expect(controller.allStats['game1']!['name'], 'Game One');
        expect(controller.allStats['game1']!['stats']['numberGames'], 10);
        expect(controller.allStats.length, 1);
      });

      test('should handle multiple games data', () {
        controller.allStats.clear();
        controller.allStats['game1'] = {
          'name': 'Game One',
          'stats': {'numberGames': 5}
        };
        controller.allStats['game2'] = {
          'name': 'Game Two', 
          'stats': {'numberGames': 3}
        };

        expect(controller.allStats.length, 2);
        expect(controller.allStats['game1']!['name'], 'Game One');
        expect(controller.allStats['game2']!['name'], 'Game Two');
      });
    });

    group('Loading state', () {
      test('should have correct initial loading state', () {
        expect(controller.isLoading, isFalse);
      });
    });
  });
}
