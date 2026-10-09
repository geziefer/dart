import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dart/services/active_routine.dart';
import 'package:dart/services/routine_generator.dart';
import 'package:dart/widget/routine_bar.dart';

Future<void> _pump(WidgetTester tester, ActiveRoutine active,
    {RoutineGenerator? gen}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ActiveRoutine>.value(
      value: active,
      child: MaterialApp(
        home: Scaffold(body: RoutineBar(generator: gen)),
      ),
    ),
  );
}

void main() {
  group('RoutineGenerator', () {
    test('picks one game from each category, in order', () {
      final r = RoutineGenerator(rng: Random(1)).generate();
      expect(r.gameIds.length, 3);
      expect(RoutineGenerator.categories[0], contains(r.gameIds[0]));
      expect(RoutineGenerator.categories[1], contains(r.gameIds[1]));
      expect(RoutineGenerator.categories[2], contains(r.gameIds[2]));
    });

    test('randomness varies the selection', () {
      // Across many seeds we should see more than one combination.
      final seen = <String>{};
      for (int s = 0; s < 20; s++) {
        seen.add(RoutineGenerator(rng: Random(s)).generate().gameIds.join(','));
      }
      expect(seen.length, greaterThan(1));
    });
  });

  group('RoutineBar', () {
    testWidgets('idle shows the start button', (tester) async {
      await _pump(tester, ActiveRoutine());
      expect(find.text('Routine starten'), findsOneWidget);
    });

    testWidgets('active routine shows next-up prompt with position',
        (tester) async {
      final active = ActiveRoutine()..start(const Routine(['99x20', 'CR', 'C40']));
      await _pump(tester, active);
      expect(find.textContaining('Routine 1/3'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
    });

    testWidgets('cancel ends the active routine', (tester) async {
      final active = ActiveRoutine()..start(const Routine(['99x20', 'CR']));
      await _pump(tester, active);
      await tester.tap(find.text('Abbrechen'));
      await tester.pump();
      expect(active.isActive, isFalse);
      // Back to idle -> start button shown, next-up prompt gone.
      expect(find.textContaining('weiter:'), findsNothing);
      expect(find.text('Routine starten'), findsOneWidget);
    });
  });
}
