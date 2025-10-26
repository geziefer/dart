import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_planhit.dart';
import 'package:dart/view/view_planhit.dart';
import 'package:dart/widget/menu.dart';

@GenerateMocks([GetStorage])
import 'planhit_widget_test.mocks.dart';

void main() {
  group('Plan Hit Game Widget Tests', () {
    late ControllerPlanHit controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('totalPoints')).thenReturn(0);
      when(mockStorage.read('recordPoints')).thenReturn(0);
      when(mockStorage.read('recordAverage')).thenReturn(0.0);
      when(mockStorage.read('longtermAverage')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      controller = ControllerPlanHit.forTesting(mockStorage);

      controller.init(MenuItem(
        id: 'test_planhit',
        name: 'Plan Hit Test',
        view: const ViewPlanHit(title: 'Plan Hit Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    testWidgets('Complete Plan Hit game workflow - all 10 rounds',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerPlanHit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewPlanHit(title: 'Plan Hit Test'),
          ),
        ),
      );

      expect(controller.currentRound, equals(0));
      expect(controller.targets.length, equals(10));
      expect(controller.hitCounts.length, equals(0));
      expect(controller.totalHits.length, equals(0));

      // Play all 10 rounds with varying hit counts
      List<int> hitSequence = [3, 2, 1, 0, 3, 2, 1, 0, 2, 1];
      int expectedTotal = 0;

      for (int round = 0; round < 10; round++) {
        int hits = hitSequence[round];
        expectedTotal += hits;

        controller.pressNumpadButton(hits);
        await tester.pumpAndSettle();

        expect(controller.currentRound, equals(round + 1));
        expect(controller.hitCounts[round], equals(hits));
        expect(controller.totalHits[round], equals(expectedTotal));
      }

      expect(controller.currentRound, equals(10));
      expect(find.byType(Dialog), findsOneWidget);

      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalPoints', expectedTotal)).called(1);
      verify(mockStorage.write('recordPoints', expectedTotal)).called(1);
      verify(mockStorage.write('recordAverage', expectedTotal / 10.0)).called(1);
      verify(mockStorage.write('longtermAverage', expectedTotal / 10.0)).called(1);
    });

    testWidgets('Plan Hit undo functionality test',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerPlanHit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewPlanHit(title: 'Plan Hit Test'),
          ),
        ),
      );

      controller.pressNumpadButton(3);
      await tester.pump();
      controller.pressNumpadButton(2);
      await tester.pump();
      controller.pressNumpadButton(1);
      await tester.pump();

      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts.length, equals(3));
      expect(controller.totalHits.length, equals(3));
      expect(controller.totalHits[2], equals(6)); // 3+2+1

      controller.pressNumpadButton(-2); // undo
      await tester.pump();

      expect(controller.currentRound, equals(2));
      expect(controller.hitCounts.length, equals(2));
      expect(controller.totalHits.length, equals(2));
      expect(controller.totalHits[1], equals(5)); // 3+2

      controller.pressNumpadButton(0);
      await tester.pump();

      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts[2], equals(0));
      expect(controller.totalHits[2], equals(5)); // No change
    });

    testWidgets('Plan Hit target generation and hit tracking',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerPlanHit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewPlanHit(title: 'Plan Hit Test'),
          ),
        ),
      );

      // Verify targets are generated
      expect(controller.targets.length, equals(10));
      for (String target in controller.targets) {
        expect(target.contains('-'), isTrue);
        List<String> numbers = target.split('-');
        expect(numbers.length, equals(3));
        for (String num in numbers) {
          int value = int.parse(num);
          expect(value, greaterThanOrEqualTo(1));
          expect(value, lessThanOrEqualTo(20));
        }
      }

      // Test hit tracking
      controller.pressNumpadButton(2);
      await tester.pump();
      expect(controller.hitCounts[0], equals(2));
      expect(controller.totalHits[0], equals(2));

      controller.pressNumpadButton(1);
      await tester.pump();
      expect(controller.hitCounts[1], equals(1));
      expect(controller.totalHits[1], equals(3));
    });

    testWidgets('Plan Hit return button for zero hits',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerPlanHit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewPlanHit(title: 'Plan Hit Test'),
          ),
        ),
      );

      controller.pressNumpadButton(-1); // Return button
      await tester.pump();

      expect(controller.currentRound, equals(1));
      expect(controller.hitCounts[0], equals(0));
      expect(controller.totalHits[0], equals(0));
    });

    testWidgets('Plan Hit stats calculation verification',
        (WidgetTester tester) async {
      disableOverflowError();

      // Set up existing stats
      when(mockStorage.read('numberGames')).thenReturn(5);
      when(mockStorage.read('totalPoints')).thenReturn(100);
      when(mockStorage.read('recordPoints')).thenReturn(25);
      when(mockStorage.read('recordAverage')).thenReturn(2.8);
      when(mockStorage.read('longtermAverage')).thenReturn(2.0);

      controller = ControllerPlanHit.forTesting(mockStorage);
      controller.init(MenuItem(
        id: 'test_planhit',
        name: 'Plan Hit Test',
        view: const ViewPlanHit(title: 'Plan Hit Test'),
        getController: (_) => controller,
        params: {},
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerPlanHit>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewPlanHit(title: 'Plan Hit Test'),
          ),
        ),
      );

      // Play perfect game (30 hits)
      for (int i = 0; i < 10; i++) {
        controller.pressNumpadButton(3);
        await tester.pump();
      }

      verify(mockStorage.write('numberGames', 6)).called(1);
      verify(mockStorage.write('totalPoints', 130)).called(1); // 100 + 30
      verify(mockStorage.write('recordPoints', 30)).called(1); // New record
      verify(mockStorage.write('recordAverage', 3.0)).called(1); // New record
      verify(mockStorage.write('longtermAverage', 2.2)).called(1); // Updated average
    });
  });
}
