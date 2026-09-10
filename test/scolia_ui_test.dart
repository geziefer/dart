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

  // The dartboard input targets a landscape tablet; give tests a matching
  // surface so the responsive layout has room (avoids RenderFlex overflow).
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(2000, 1400);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

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
    // Turn not submitted until takeout.
    expect(controller.remaining, 501);

    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    expect(controller.remaining, 501 - 180);
  });

  testWidgets('ScoliaDartboard caps a turn at 3 darts', (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_cap',
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
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;
    // Four darts thrown, only the first three count.
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20'); // ignored (turn full)
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    expect(controller.remaining, 501 - 180);
  });

  testWidgets('ScoliaDartboard miss button adds a 0-value dart',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_miss',
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
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;
    state.pressDartboard('T20'); // 60
    await tester.tap(find.byIcon(Icons.block)); // miss = 0
    await tester.pump();
    await tester.tap(find.byIcon(Icons.pan_tool)); // end turn
    await tester.pump();
    // 60 + 0 = 60
    expect(controller.remaining, 501 - 60);
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
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    expect(controller.remaining, 501 - 50);
  });
}
