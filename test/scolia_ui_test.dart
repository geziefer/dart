import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/scolia_dartboard.dart';

@GenerateMocks([GetStorage])
import 'scolia_ui_test.mocks.dart';

MockGetStorage _freshStorage() {
  final s = MockGetStorage();
  when(s.read(any)).thenReturn(null);
  when(s.write(any, any)).thenAnswer((_) async {});
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'ScoliaDartboard simulator: tapping T20 x3 then end-turn drives x01 by 180',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_x01',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));

    // Reach into the widget's DartboardController state to simulate throws
    // without relying on precise tap coordinates on the CustomPaint.
    final state = tester.state(find.byType(ScoliaDartboard))
        as DartboardController;

    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    // Turn not submitted until "Wurf beenden".
    expect(controller.remaining, 501);

    await tester.tap(find.text('Wurf beenden'));
    await tester.pump();

    expect(controller.remaining, 501 - 180);
  });

  testWidgets('ScoliaDartboard normalises DB->Bull (inner bull = 50)',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_x01b',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));

    final state = tester.state(find.byType(ScoliaDartboard))
        as DartboardController;
    state.pressDartboard('DB'); // inner bull
    await tester.tap(find.text('Wurf beenden'));
    await tester.pump();

    expect(controller.remaining, 501 - 50);
  });
}
