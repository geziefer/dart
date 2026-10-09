import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/widget/trend_sparkline.dart';

void main() {
  testWidgets('shows a dash with fewer than two values', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TrendSparkline(values: [5])),
    ));
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('renders the sparkline text-free for multiple values',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TrendSparkline(values: [10, 20, 15, 30], higherIsBetter: true),
      ),
    ));
    // No dash placeholder when a real sparkline is drawn.
    expect(find.text('—'), findsNothing);
  });
}
