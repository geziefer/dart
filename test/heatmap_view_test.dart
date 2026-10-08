import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/throw_log_model.dart';
import 'package:dart/widget/heatmap_view.dart';
LoggedDart _dart({
  int segment = 20,
  String ring = 'triple',
  int value = 60,
  double? x,
  double? y,
}) =>
    LoggedDart(segment: segment, ring: ring, value: value, x: x, y: y);

Future<void> _pump(WidgetTester tester, List<LoggedDart> darts) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 500,
          height: 560,
          child: HeatmapView(darts: darts, title: 'Wurfbild'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows empty state when no darts carry coordinates',
      (tester) async {
    await _pump(tester, [
      _dart(), // no x/y
      _dart(ring: 'single', value: 20),
    ]);

    expect(find.textContaining('Noch keine Wurfdaten'), findsOneWidget);
    expect(find.textContaining('Darts'), findsNothing); // no count footer
  });

  testWidgets('empty list shows empty state', (tester) async {
    await _pump(tester, const []);
    expect(find.textContaining('Noch keine Wurfdaten'), findsOneWidget);
  });

  testWidgets('renders the board + plots darts and shows the count footer',
      (tester) async {
    await _pump(tester, [
      _dart(x: 0, y: 0, ring: 'innerBull', value: 50), // centre
      _dart(x: 100, y: -50, ring: 'triple', value: 60),
      _dart(x: -120, y: 80, ring: 'double', value: 40),
    ]);

    // The empty-state message is gone.
    expect(find.textContaining('Noch keine Wurfdaten'), findsNothing);
    // The board is drawn via a CustomPaint.
    expect(find.byType(CustomPaint), findsWidgets);
    // Footer reports the number of plottable darts.
    expect(find.text('3 Darts'), findsOneWidget);
    // Title is shown.
    expect(find.text('Wurfbild'), findsOneWidget);
  });

  testWidgets('counts only darts with coordinates in the footer',
      (tester) async {
    await _pump(tester, [
      _dart(x: 0, y: 0),
      _dart(x: 10, y: 10),
      _dart(), // no coords -> excluded
    ]);
    expect(find.text('2 Darts'), findsOneWidget);
  });
}
