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
        controller: controller,
        params: {'xxx': 501, 'max': -1, 'end': 100},
      ));
    });

    /// Tests XXXCheckout widget creation and initial state
    /// Verifies: widget can be created and displays correctly
    testWidgets('XXXCheckout widget creation and initial state', (WidgetTester tester) async {
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
    testWidgets('XXXCheckout basic input building', (WidgetTester tester) async {
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
  });
}
