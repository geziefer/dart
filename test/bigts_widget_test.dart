import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_bigts.dart';
import 'package:dart/view/view_bigts.dart';
import 'package:dart/widget/menu.dart';

@GenerateMocks([GetStorage])
import 'bigts_widget_test.mocks.dart';

void main() {
  group('Big Ts Game Widget Tests', () {
    late ControllerBigTs controller;
    late MockGetStorage mockStorage;

    setUp(() {
      mockStorage = MockGetStorage();

      when(mockStorage.read('numberGames')).thenReturn(0);
      when(mockStorage.read('totalPoints')).thenReturn(0);
      when(mockStorage.read('recordRoundPoints')).thenReturn(0);
      when(mockStorage.read('recordRoundAverage')).thenReturn(0.0);
      when(mockStorage.read('longtermAverage')).thenReturn(0.0);
      when(mockStorage.write(any, any)).thenAnswer((_) async {});

      controller = ControllerBigTs.forTesting(mockStorage);

      controller.init(MenuItem(
        id: 'test_bigts',
        name: 'Big Ts Test',
        view: const ViewBigTs(title: 'Big Ts Test'),
        getController: (_) => controller,
        params: {},
      ));
    });

    testWidgets('Complete Big Ts game workflow - all 10 rounds',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
          ),
        ),
      );

      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));
      expect(controller.points.length, equals(0));

      // Play 10 rounds with varying hits
      List<int> roundHits = [3, 2, 1, 0, 3, 2, 1, 3, 2, 1];
      List<int> expectedPoints = [6, 3, 1, 0, 6, 3, 1, 6, 3, 1];
      int cumulativeTotal = 0;

      for (int round = 0; round < 10; round++) {
        controller.pressNumpadButton(roundHits[round]);
        await tester.pumpAndSettle();

        cumulativeTotal += expectedPoints[round];

        expect(controller.currentRound, equals(round + 1));
        expect(controller.hitCounts[round], equals(roundHits[round]));
        expect(controller.points[round], equals(expectedPoints[round]));
        expect(controller.totalPoints[round], equals(cumulativeTotal));
      }

      expect(controller.currentRound, equals(10));
      expect(find.byType(Dialog), findsOneWidget);

      verify(mockStorage.write('numberGames', 1)).called(1);
      verify(mockStorage.write('totalPoints', 30)).called(1);
    });

    testWidgets('Big Ts undo functionality test', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
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

      controller.pressNumpadButton(-2);
      await tester.pump();

      expect(controller.currentRound, equals(2));
      expect(controller.hitCounts.length, equals(2));
      expect(controller.points.length, equals(2));
      expect(controller.totalPoints.length, equals(2));

      controller.pressNumpadButton(0);
      await tester.pump();

      expect(controller.currentRound, equals(3));
      expect(controller.hitCounts[2], equals(0));
      expect(controller.points[2], equals(0));
    });

    testWidgets('Big Ts point calculation verification',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
          ),
        ),
      );

      // Test all possible hit counts
      Map<int, int> hitToPoints = {0: 0, 1: 1, 2: 3, 3: 6};

      int cumulativeTotal = 0;
      for (int hits in [0, 1, 2, 3]) {
        controller.pressNumpadButton(hits);
        await tester.pump();

        int expectedPoints = hitToPoints[hits]!;
        cumulativeTotal += expectedPoints;

        expect(controller.points.last, equals(expectedPoints));
        expect(controller.totalPoints.last, equals(cumulativeTotal));
      }
    });

    testWidgets('Big Ts return button for zero hits',
        (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
          ),
        ),
      );

      controller.pressNumpadButton(-1);
      await tester.pump();

      expect(controller.currentRound, equals(1));
      expect(controller.hitCounts[0], equals(0));
      expect(controller.points[0], equals(0));
      expect(controller.totalPoints[0], equals(0));
    });

    testWidgets('Big Ts input validation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
          ),
        ),
      );

      controller.pressNumpadButton(4);
      await tester.pump();
      controller.pressNumpadButton(-3);
      await tester.pump();
      controller.pressNumpadButton(10);
      await tester.pump();

      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));

      for (int validInput in [0, 1, 2, 3]) {
        controller.pressNumpadButton(validInput);
        await tester.pump();
      }

      expect(controller.currentRound, equals(4));
      expect(controller.hitCounts.length, equals(4));
    });

    testWidgets('Big Ts average calculation', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
          ),
        ),
      );

      // Test 1: Beginning - average should be 0
      expect(controller.currentRound, equals(0));
      double initialAverage = controller.currentRound > 0 
          ? (controller.totalPoints.isNotEmpty ? controller.totalPoints.last : 0) / controller.currentRound 
          : 0.0;
      expect(initialAverage, equals(0.0));

      // Test 2: First round - 3 hits (6 points)
      controller.pressNumpadButton(3);
      await tester.pump();
      
      double avgAfterRound1 = controller.totalPoints.last / controller.currentRound;
      expect(avgAfterRound1, equals(6.0)); // 6 points / 1 round = 6.0

      // Test 3: Second round - 2 hits (3 points)
      controller.pressNumpadButton(2);
      await tester.pump();
      
      double avgAfterRound2 = controller.totalPoints.last / controller.currentRound;
      expect(avgAfterRound2, equals(4.5)); // 9 points / 2 rounds = 4.5

      // Test 4: Third round - 1 hit (1 point)
      controller.pressNumpadButton(1);
      await tester.pump();
      
      double avgAfterRound3 = controller.totalPoints.last / controller.currentRound;
      expect(avgAfterRound3, closeTo(3.33, 0.01)); // 10 points / 3 rounds = 3.33...

      // Test 5: Complete game with remaining rounds
      for (int i = 0; i < 7; i++) {
        controller.pressNumpadButton(2); // 7 more rounds with 2 hits each (3 points)
      }
      await tester.pump();

      // Final: (6 + 3 + 1 + 7*3) / 10 = (10 + 21) / 10 = 3.1
      double finalAverage = controller.totalPoints.last / controller.currentRound;
      expect(finalAverage, equals(3.1));
    });

    testWidgets('Big Ts undo edge cases', (WidgetTester tester) async {
      disableOverflowError();

      await tester.pumpWidget(
        ChangeNotifierProvider<ControllerBigTs>(
          create: (_) => controller,
          child: MaterialApp(
            home: const ViewBigTs(title: 'Big Ts Test'),
          ),
        ),
      );

      controller.pressNumpadButton(-2);
      await tester.pump();

      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));

      controller.pressNumpadButton(2);
      await tester.pump();
      controller.pressNumpadButton(-2);
      await tester.pump();

      expect(controller.currentRound, equals(0));
      expect(controller.hitCounts.length, equals(0));
      expect(controller.points.length, equals(0));
      expect(controller.totalPoints.length, equals(0));
    });
  });
}
