import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/controller/controller_stats.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
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

    group('File operations', () {
      test('should handle file export operations', () async {
        controller.allStats['test'] = {
          'name': 'Test',
          'stats': {'numberGames': 1}
        };

        // Test export file generation
        final exportData = await controller.exportStats();
        expect(exportData, contains('"version":"1.0"'));
        expect(exportData, contains('"test"'));
      });
    });

    group('Stats management', () {
      test('should clear all stats', () {
        controller.allStats['test'] = {'name': 'Test', 'stats': {}};
        
        controller.allStats.clear();
        expect(controller.allStats.isEmpty, isTrue);
      });

      test('should handle stats display data', () {
        controller.allStats['game1'] = {
          'name': 'Game One',
          'stats': {
            'numberGames': 5,
            'totalPoints': 100,
            'recordRoundPoints': 25,
          }
        };
        controller.allStats['game2'] = {
          'name': 'Game Two',
          'stats': {
            'numberGames': 3,
            'recordDarts': 15,
          }
        };

        expect(controller.allStats.isNotEmpty, isTrue);
        expect(controller.allStats.length, equals(2));
        
        // Test that stats can be accessed for display
        final game1Stats = controller.allStats['game1']!['stats'];
        expect(game1Stats['numberGames'], equals(5));
        expect(game1Stats['totalPoints'], equals(100));
      });

      test('should handle empty stats for view display', () {
        controller.allStats.clear();
        
        expect(controller.allStats.isEmpty, isTrue);
        // View should show "Keine Statistik vorhanden" when empty
      });

      test('should format stats data for display', () {
        controller.allStats['test_game'] = {
          'name': 'Test Game',
          'stats': {
            'numberGames': 10,
            'recordScore': 85.5,
            'longtermScore': 75.2,
          }
        };

        final gameData = controller.allStats['test_game']!;
        expect(gameData['name'], equals('Test Game'));
        
        final stats = gameData['stats'];
        expect(stats['numberGames'], equals(10));
        expect(stats['recordScore'], equals(85.5));
        expect(stats['longtermScore'], equals(75.2));
      });
    });

    group('Loading state', () {
      test('should have correct initial loading state', () {
        expect(controller.isLoading, isFalse);
      });
    });
  });
}
