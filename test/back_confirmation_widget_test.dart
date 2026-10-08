import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import 'package:dart/controller/controller_killbull.dart';
import 'package:dart/view/view_killbull.dart';
import 'package:dart/widget/menu.dart';

// Reuse the generated mock from the killbull test.
@GenerateMocks([GetStorage])
import 'back_confirmation_widget_test.mocks.dart';

/// Pumps a menu-like screen that pushes the KillBull game, so we can observe
/// whether tapping the back arrow returns to the menu or asks for confirmation.
Future<void> _pumpGame(WidgetTester tester, ControllerKillBull controller) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ControllerKillBull>.value(
      value: controller,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ViewKillBull(title: 'Kill Bull'),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  late ControllerKillBull controller;
  late MockGetStorage mockStorage;

  setUp(() {
    mockStorage = MockGetStorage();
    when(mockStorage.read(any)).thenReturn(0);
    when(mockStorage.read('longtermScore')).thenReturn(0.0);
    when(mockStorage.write(any, any)).thenAnswer((_) async {});
    controller = ControllerKillBull.forTesting(mockStorage);
    controller.init(MenuItem(
      id: 'test_killbull',
      name: 'Kill Bull',
      view: const ViewKillBull(title: 'Kill Bull'),
      getController: (_) => controller,
      params: const {},
    ));
  });

  testWidgets('back arrow leaves immediately when no progress was made',
      (tester) async {
    disableOverflowError();
    await _pumpGame(tester, controller);

    // Fresh game: no progress.
    expect(controller.hasGameProgress, isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // No confirmation dialog; we are back on the menu screen.
    expect(find.text('Spiel verlassen?'), findsNothing);
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('back arrow asks for confirmation once progress was made',
      (tester) async {
    disableOverflowError();
    await _pumpGame(tester, controller);

    // Make progress: throw a round.
    controller.pressNumpadButton(3);
    await tester.pumpAndSettle();
    expect(controller.hasGameProgress, isTrue);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Confirmation dialog appears; still on the game screen.
    expect(find.text('Spiel verlassen?'), findsOneWidget);
    expect(find.text('OPEN'), findsNothing);

    // Cancel keeps us in the game.
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Spiel verlassen?'), findsNothing);
    expect(find.text('OPEN'), findsNothing); // still in game

    // Back again, this time confirm leaving.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verlassen'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN'), findsOneWidget); // back on the menu
  });
}
