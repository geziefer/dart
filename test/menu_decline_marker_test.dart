import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/widget/menu.dart' as app;

void main() {
  testWidgets('menu tile shows no decline marker without history',
      (tester) async {
    final item = app.MenuItem(
      id: 'ZZZ_no_history',
      name: 'Test',
      view: const SizedBox.shrink(),
      getController: (_) => throw UnimplementedError(),
      params: const {},
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: app.MenuItemButton(menuItem: item)),
    ));

    expect(find.text('Test'), findsOneWidget);
    // No history (and no highscore config) -> no decline marker.
    expect(find.byIcon(Icons.trending_down), findsNothing);
  });
}
