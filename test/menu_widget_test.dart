import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/view/view_halfit.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';

// Import existing mocks
import 'halfit_widget_test.mocks.dart';

// Mock BuildContext for testing
class MockBuildContext extends Mock implements BuildContext {}

@GenerateMocks([GetStorage])
void main() {
  group('Menu Widget Business Logic Tests', () {
    late MockGetStorage mockStorage;
    late MockBuildContext mockContext;

    setUp(() {
      mockStorage = MockGetStorage();
      mockContext = MockBuildContext();

      // Set up default mock responses
      when(mockStorage.read(any)).thenReturn(null);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});
    });

    /// Tests Menu widget MenuItem creation and validation
    /// Verifies: MenuItem objects are created correctly with all required properties
    test('Menu MenuItem creation and validation', () {
      final controller = ControllerHalfit.forTesting(mockStorage);

      // Test MenuItem creation with all required properties
      final menuItem = MenuItem(
        id: 'test_game',
        name: 'Test Game',
        view: const ViewHalfit(title: 'Test Game'),
        getController: (context) => controller,
        params: {'testParam': 'testValue'},
      );

      // Assert: MenuItem properties are set correctly
      expect(menuItem.id, equals('test_game'));
      expect(menuItem.name, equals('Test Game'));
      expect(menuItem.view, isA<ViewHalfit>());
      expect(menuItem.params, equals({'testParam': 'testValue'}));
      expect(menuItem.getController, isA<Function>());

      // Test controller retrieval
      final retrievedController = menuItem.getController(mockContext);
      expect(retrievedController, equals(controller));
    });

    /// Tests Menu widget game configurations
    /// Verifies: Different game types have correct MenuItem configurations
    test('Menu game configurations validation', () {
      final halfitController = ControllerHalfit.forTesting(mockStorage);
      final checkoutController = ControllerXXXCheckout.forTesting(mockStorage);

      // Test HalfIt game configuration
      final halfitMenuItem = MenuItem(
        id: 'halfit',
        name: 'Half It',
        view: const ViewHalfit(title: 'Half It'),
        getController: (context) => halfitController,
        params: {},
      );

      expect(halfitMenuItem.id, equals('halfit'));
      expect(halfitMenuItem.name, equals('Half It'));
      expect(halfitMenuItem.params, isEmpty);

      // Test XXXCheckout game configurations (from actual menu.dart)
      final checkoutConfigs = [
        {
          'id': '170m3',
          'name': '170 x 10\nmax 3',
          'params': {'xxx': 170, 'max': 3, 'end': 10},
        },
        {
          'id': '501x5',
          'name': '501 x 5',
          'params': {'xxx': 501, 'max': -1, 'end': 5},
        },
        {
          'id': '301x3',
          'name': '301 x 3',
          'params': {'xxx': 301, 'max': -1, 'end': 3},
        },
      ];

      for (final config in checkoutConfigs) {
        final menuItem = MenuItem(
          id: config['id'] as String,
          name: config['name'] as String,
          view: const ViewXXXCheckout(title: 'Test'),
          getController: (context) => checkoutController,
          params: config['params'] as Map<String, dynamic>,
        );

        expect(menuItem.id, equals(config['id']));
        expect(menuItem.name, equals(config['name']));
        expect(menuItem.params, equals(config['params']));
      }
    });

    /// Tests Menu widget controller initialization logic
    /// Verifies: Controllers are properly initialized when MenuItem.init() is called
    test('Menu controller initialization logic', () {
      final halfitController = ControllerHalfit.forTesting(mockStorage);
      final checkoutController = ControllerXXXCheckout.forTesting(mockStorage);

      // Test HalfIt controller initialization
      final halfitMenuItem = MenuItem(
        id: 'halfit_test',
        name: 'Half It Test',
        view: const ViewHalfit(title: 'Half It Test'),
        getController: (context) => halfitController,
        params: {},
      );

      // Simulate menu button press logic: get controller and initialize
      final retrievedHalfitController =
          halfitMenuItem.getController(mockContext) as ControllerHalfit;
      retrievedHalfitController.init(halfitMenuItem);

      // Assert: HalfIt controller initialized correctly
      expect(retrievedHalfitController.item, equals(halfitMenuItem));
      expect(retrievedHalfitController.round, equals(1));
      expect(retrievedHalfitController.totalScore, equals(40));
      expect(retrievedHalfitController.rounds.length, equals(1));
      expect(retrievedHalfitController.rounds[0], equals('15'));

      // Test XXXCheckout controller initialization with parameters
      final checkoutMenuItem = MenuItem(
        id: '501_test',
        name: '501 Test',
        view: const ViewXXXCheckout(title: '501 Test'),
        getController: (context) => checkoutController,
        params: {'xxx': 501, 'max': -1, 'end': 5},
      );

      final retrievedCheckoutController =
          checkoutMenuItem.getController(mockContext) as ControllerXXXCheckout;
      retrievedCheckoutController.init(checkoutMenuItem);

      // Assert: XXXCheckout controller initialized with correct parameters
      expect(retrievedCheckoutController.item, equals(checkoutMenuItem));
      expect(retrievedCheckoutController.xxx, equals(501));
      expect(retrievedCheckoutController.max, equals(-1));
      expect(retrievedCheckoutController.end, equals(5));
      expect(retrievedCheckoutController.remaining, equals(501));
      expect(retrievedCheckoutController.leg, equals(1));
    });

    /// Tests Menu widget fresh game state logic
    /// Verifies: Controllers are reset to fresh state when reinitialized
    test('Menu fresh game state logic', () {
      final controller = ControllerHalfit.forTesting(mockStorage);

      final menuItem = MenuItem(
        id: 'fresh_test',
        name: 'Fresh Test',
        view: const ViewHalfit(title: 'Fresh Test'),
        getController: (context) => controller,
        params: {},
      );

      // Initialize and modify controller state
      controller.init(menuItem);
      controller.pressNumpadButton(3);
      controller.pressNumpadButton(0);
      controller.pressNumpadButton(-1); // Submit score

      // Verify state was modified
      expect(controller.scores.length, equals(1));
      expect(controller.round, equals(2));
      expect(controller.totalScore, equals(70));

      // Reinitialize (simulates fresh game start from menu)
      controller.init(menuItem);

      // Assert: Controller state was reset to fresh game state
      expect(controller.scores.length, equals(0));
      expect(controller.round, equals(1));
      expect(controller.totalScore, equals(40));
      expect(controller.input, equals(""));
      expect(controller.rounds.length, equals(1));
      expect(controller.rounds[0], equals('15'));
    });

    /// Tests Menu widget parameter validation
    /// Verifies: MenuItem parameters are properly validated and used
    test('Menu parameter validation', () {
      final controller = ControllerXXXCheckout.forTesting(mockStorage);

      // Test various parameter combinations
      final parameterTests = [
        {'xxx': 170, 'max': 3, 'end': 10},
        {'xxx': 501, 'max': -1, 'end': 5},
        {'xxx': 301, 'max': 15, 'end': 3},
        {'xxx': 701, 'max': -1, 'end': 1},
      ];

      for (final params in parameterTests) {
        final menuItem = MenuItem(
          id: 'param_test',
          name: 'Parameter Test',
          view: const ViewXXXCheckout(title: 'Parameter Test'),
          getController: (context) => controller,
          params: params,
        );

        controller.init(menuItem);

        // Assert: Parameters were applied correctly
        expect(controller.xxx, equals(params['xxx']));
        expect(controller.max, equals(params['max']));
        expect(controller.end, equals(params['end']));
        expect(controller.remaining, equals(params['xxx']));
      }
    });

    /// Tests Menu widget grid layout business logic
    /// Verifies: Menu games list structure and organization
    test('Menu grid layout business logic', () {
      // Test that Menu.games list has expected structure (from menu.dart)
      // This tests the business logic of game organization, not UI rendering

      // Verify games list exists and has reasonable size
      expect(Menu.games, isA<List<MenuItem>>());
      expect(Menu.games.length, greaterThan(0));
      expect(Menu.games.length, lessThanOrEqualTo(20)); // 4x5 grid maximum

      // Verify all games have required properties
      for (final game in Menu.games) {
        expect(game.id, isA<String>());
        expect(game.id.isNotEmpty, isTrue);
        expect(game.name, isA<String>());
        expect(game.name.isNotEmpty, isTrue);
        expect(game.view, isA<Widget>());
        expect(game.getController, isA<Function>());
        expect(game.params, isA<Map<String, dynamic>>());
      }

      // Verify game IDs are unique
      final gameIds = Menu.games.map((game) => game.id).toList();
      final uniqueIds = gameIds.toSet();
      expect(gameIds.length, equals(uniqueIds.length));

      // Test specific game types are present
      final gameTypes = Menu.games.map((game) => game.view.runtimeType).toSet();
      expect(gameTypes.contains(ViewHalfit), isTrue);
      expect(gameTypes.contains(ViewXXXCheckout), isTrue);
    });

    /// Tests Menu.games static data structure comprehensive validation
    /// Verifies: All games in the static list have proper structure and parameters
    test('Menu games comprehensive data validation', () {
      // Test that the static games list is properly structured
      expect(Menu.games, isA<List<MenuItem>>());
      expect(Menu.games.length, greaterThan(15)); // Should have many games
      expect(Menu.games.length, lessThanOrEqualTo(20)); // 4x5 grid maximum

      // Test specific games exist (exercises the static data)
      final gameIds = Menu.games.map((game) => game.id).toList();
      expect(gameIds.contains('HI'), isTrue); // Half It
      expect(gameIds.contains('501x5'), isTrue); // 501 x 5
      expect(gameIds.contains('170m3'), isTrue); // 170 max 3
      expect(gameIds.contains('C40'), isTrue); // Catch 40
      expect(gameIds.contains('KB'), isTrue); // Kill Bull

      // Test game names
      final gameNames = Menu.games.map((game) => game.name).toList();
      expect(gameNames.contains('Half it'), isTrue);
      expect(gameNames.contains('501 x 5'), isTrue);
      expect(gameNames.contains('Catch 40'), isTrue);

      // Verify all games have required properties
      for (final game in Menu.games) {
        expect(game.id, isA<String>());
        expect(game.id.isNotEmpty, isTrue);
        expect(game.name, isA<String>());
        expect(game.name.isNotEmpty, isTrue);
        expect(game.view, isA<Widget>());
        expect(game.getController, isA<Function>());
        expect(game.params, isA<Map<String, dynamic>>());
      }

      // Test parameter structures for different game types
      final xxxCheckoutGames =
          Menu.games.where((game) => game.params.containsKey('xxx')).toList();
      expect(xxxCheckoutGames.length, greaterThan(0));

      for (final game in xxxCheckoutGames) {
        expect(game.params['xxx'], isA<int>());
        expect(game.params['max'], isA<int>());
        expect(game.params['end'], isA<int>());
      }

      final finishQuestGames = Menu.games
          .where((game) => game.id == 'FQ')
          .toList();
      expect(finishQuestGames.length, greaterThan(0));

      for (final game in finishQuestGames) {
        expect(game.id, equals('FQ'));
        expect(game.name, equals('FinishQuest'));
      }
    });

    /// Tests MenuItem constructor business logic
    /// Verifies: MenuItem objects can be created with various parameter combinations
    test('MenuItem constructor business logic', () {
      final controller = ControllerHalfit.forTesting(mockStorage);

      // Test MenuItem creation with different parameter types
      final testCases = [
        {
          'id': 'test1',
          'name': 'Test 1',
          'params': <String, dynamic>{},
        },
        {
          'id': 'test2',
          'name': 'Test 2',
          'params': {'xxx': 501, 'max': -1, 'end': 5},
        },
        {
          'id': 'test3',
          'name': 'Test 3',
          'params': {'from': 61, 'to': 82},
        },
        {
          'id': 'test4',
          'name': 'Test 4',
          'params': {'duration': 60, 'max': 10},
        },
      ];

      for (final testCase in testCases) {
        final menuItem = MenuItem(
          id: testCase['id'] as String,
          name: testCase['name'] as String,
          view: const ViewHalfit(title: 'Test'),
          getController: (context) => controller,
          params: testCase['params'] as Map<String, dynamic>,
        );

        expect(menuItem.id, equals(testCase['id']));
        expect(menuItem.name, equals(testCase['name']));
        expect(menuItem.params, equals(testCase['params']));
        expect(menuItem.view, isA<ViewHalfit>());
        expect(menuItem.getController, isA<Function>());
      }
    });

    /// Tests Menu widget constructor business logic
    /// Verifies: Menu widget can be instantiated
    test('Menu widget constructor business logic', () {
      const menu = Menu();

      // Verify Menu widget can be created
      expect(menu, isA<Menu>());
      expect(menu, isA<StatelessWidget>());

      // Verify Menu.games static list is accessible
      expect(Menu.games, isA<List<MenuItem>>());
      expect(Menu.games.isNotEmpty, isTrue);
    });

    /// Tests Menu widget grid layout calculation business logic
    /// Verifies: Grid layout calculations for 4x5 arrangement
    test('Menu grid layout calculation logic', () {
      // Test grid layout business logic (from build method)
      const int crossAxisCount = 4; // 4 columns
      const double crossAxisSpacing = 8.0;
      const double mainAxisSpacing = 8.0;
      const double padding = 8.0;

      // Test that games fit in 4x5 grid
      final totalGames = Menu.games.length;
      const maxGridItems = 4 * 5; // 4 columns × 5 rows
      expect(totalGames, lessThanOrEqualTo(maxGridItems));

      // Test grid calculations for different screen sizes
      final testCases = [
        {'width': 400.0, 'height': 600.0},
        {'width': 800.0, 'height': 1000.0},
        {'width': 1200.0, 'height': 800.0},
      ];

      for (final testCase in testCases) {
        final availableWidth = testCase['width']! - (padding * 2);
        final availableHeight = testCase['height']! - (padding * 2);

        // Calculate item dimensions (from build method logic)
        final itemWidth =
            (availableWidth - (3 * crossAxisSpacing)) / crossAxisCount;
        final itemHeight =
            (availableHeight - (4 * mainAxisSpacing)) / 5; // 5 rows
        final aspectRatio = itemWidth / itemHeight;

        expect(itemWidth, greaterThan(0));
        expect(itemHeight, greaterThan(0));
        expect(aspectRatio, greaterThan(0));
      }
    });

    /// Tests Menu widget navigation business logic
    /// Verifies: Navigation logic when menu items are pressed
    test('Menu navigation business logic', () {
      final controller = ControllerHalfit.forTesting(mockStorage);

      final menuItem = MenuItem(
        id: 'nav_test',
        name: 'Navigation Test',
        view: const ViewHalfit(title: 'Navigation Test'),
        getController: (context) => controller,
        params: {'testParam': 'testValue'},
      );

      // Test navigation preparation logic (from MenuItemButton onPressed)
      // 1. Get controller from provider
      final retrievedController = menuItem.getController(mockContext);
      expect(retrievedController, equals(controller));

      // 2. Initialize controller with fresh game state
      retrievedController.init(menuItem);

      // 3. Verify controller is ready for navigation (cast to specific type for testing)
      final halfitController = retrievedController as ControllerHalfit;
      expect(halfitController.round, equals(1));
      expect(halfitController.totalScore, equals(40));
      expect(halfitController.input, equals(""));
    });

    /// Tests Menu widget game type categorization business logic
    /// Verifies: Games are properly categorized by type and parameters
    test('Menu game type categorization logic', () {
      // Categorize games by type (business logic analysis)
      final xxxCheckoutGames = <MenuItem>[];
      final finishQuestGames = <MenuItem>[];
      final rtcGames = <MenuItem>[];
      final specialGames = <MenuItem>[];

      for (final game in Menu.games) {
        if (game.params.containsKey('xxx')) {
          xxxCheckoutGames.add(game);
        } else if (game.id == 'FQ') {
          finishQuestGames.add(game);
        } else if (game.id.startsWith('RTC')) {
          rtcGames.add(game);
        } else {
          specialGames.add(game);
        }
      }

      // Verify categorization results
      expect(xxxCheckoutGames.length, greaterThan(0));
      expect(finishQuestGames.length, greaterThan(0));
      expect(specialGames.length, greaterThan(0));

      // Test XXXCheckout games have valid parameters
      for (final game in xxxCheckoutGames) {
        expect(game.params['xxx'], isA<int>());
        expect(game.params['xxx'], greaterThan(0));
        expect(game.params['max'], isA<int>());
        expect(game.params['end'], isA<int>());
        expect(game.params['end'], greaterThan(0));
      }

      // Test FinishQuest games have valid ranges
      for (final game in finishQuestGames) {
        expect(game.id, equals('FQ'));
        expect(game.name, equals('FinishQuest'));
      }
    });

    /// Tests Menu widget game difficulty progression business logic
    /// Verifies: Games are arranged with logical difficulty progression
    test('Menu game difficulty progression logic', () {
      // Test XXXCheckout difficulty progression
      final checkoutGames =
          Menu.games.where((game) => game.params.containsKey('xxx')).toList();

      // Find specific difficulty levels
      final game170 =
          checkoutGames.firstWhere((game) => game.params['xxx'] == 170);
      final game501 =
          checkoutGames.firstWhere((game) => game.params['xxx'] == 501);

      expect(game170.params['xxx'], lessThan(game501.params['xxx']));

      // Test FinishQuest game exists
      final finishGames = Menu.games
          .where((game) => game.id == 'FQ')
          .toList();
      expect(finishGames.length, equals(1));
      expect(finishGames.first.name, equals('FinishQuest'));
    });

    /// Tests Menu widget parameter validation business logic
    /// Verifies: All game parameters are within valid ranges
    test('Menu parameter range validation logic', () {
      for (final game in Menu.games) {
        // Test XXXCheckout parameter ranges
        if (game.params.containsKey('xxx')) {
          final xxx = game.params['xxx'] as int;
          final max = game.params['max'] as int;
          final end = game.params['end'] as int;

          expect(xxx, greaterThan(0));
          expect(xxx, lessThanOrEqualTo(701)); // Reasonable upper limit
          expect(end, greaterThan(0));
          expect(end, lessThanOrEqualTo(10)); // Reasonable game count

          if (max > 0) {
            expect(max, greaterThan(0));
            expect(max, lessThanOrEqualTo(20)); // Reasonable attempt limit
          }
        }

        // Test FinishQuest game structure
        if (game.id == 'FQ') {
          expect(game.name, equals('FinishQuest'));
        }

        // Test duration parameters
        if (game.params.containsKey('duration')) {
          final duration = game.params['duration'] as int;
          expect(duration, greaterThan(0));
          expect(duration, lessThanOrEqualTo(300)); // Max 5 minutes
        }
      }
    });
  });
}
