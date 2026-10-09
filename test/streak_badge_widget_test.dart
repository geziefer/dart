import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/streak_service.dart';
import 'package:dart/widget/streak_badge.dart';

Future<void> _pump(WidgetTester tester, StreakInfo info) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: StreakBadge(gameIds: const ['A'], info: info),
    ),
  ));
}

void main() {
  testWidgets('hidden when no activity', (tester) async {
    await _pump(tester,
        const StreakInfo(currentStreak: 0, trainedToday: false, daysThisWeek: 0));
    expect(find.byIcon(Icons.local_fire_department), findsNothing);
  });

  testWidgets('shows streak and weekly count', (tester) async {
    await _pump(tester,
        const StreakInfo(currentStreak: 3, trainedToday: true, daysThisWeek: 4));
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4/7'), findsOneWidget);
  });

  testWidgets('renders when trained earlier in week but not today',
      (tester) async {
    await _pump(tester,
        const StreakInfo(currentStreak: 0, trainedToday: false, daysThisWeek: 2));
    // Flame still shown (weekly activity > 0), streak 0.
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('2/7'), findsOneWidget);
  });
}
