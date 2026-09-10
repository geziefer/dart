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

  testWidgets('correction: tap a thrown number, then re-tap board to fix it',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_corr',
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

    // Throw T20, T20, T20 (would be 180).
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    await tester.pump();

    // Misclick correction: select the 3rd dart (index 2) and set it to T19.
    // Tap the last "60" button. There are three "60" texts; tap the last.
    await tester.tap(find.text('60').last);
    await tester.pump();
    state.pressDartboard('T19'); // corrects selected dart to 57
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pan_tool)); // takeout submits
    await tester.pump();

    // 60 + 60 + 57 = 177
    expect(controller.remaining, 501 - 177);
  });

  testWidgets('round undo icon reverses the last submitted round',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_undo',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(
          controller: controller,
          simulator: true,
          onUndoRound: () => controller.pressNumpadButton(-2),
        ),
      ),
    ));
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    // Submit a 180 round.
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    expect(controller.remaining, 501 - 180);

    // Undo the whole round.
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    expect(controller.remaining, 501);
  });

  testWidgets('mid-round finish on a single dart wins the leg', (tester) async {
    // Start at 20 so one dart (D10 = 20) checks out.
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_finish',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 20, 'max': -1, 'end': 5},
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    expect(controller.wins, 0);
    // One dart only, then take out (finish mid-round).
    state.pressDartboard('D10'); // 20
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    expect(controller.wins, 1); // leg won on a single-dart turn
  });

  testWidgets('Scolia checkout auto-corrects the dart count (no dialog)',
      (tester) async {
    // Start at 20; finish with a single dart (D10). No checkout dialog should
    // be needed; the dart count is taken from the turn (1 dart).
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_autoco',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 20, 'max': -1, 'end': 5},
    ));
    // If the dialog were used, the view would set onShowCheckout; leaving it
    // null proves the leg completes without any dialog interaction.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    state.pressDartboard('D10'); // 20, single dart
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    expect(controller.wins, 1);
    // totalDarts should reflect 1 dart used (3 counted, corrected by 2), not 3.
    expect(controller.totalDarts, 1);
  });

  testWidgets('170 game: 138 then single-dart 32 finish -> 4-dart average',
      (tester) async {
    // Reproduces the reported scenario: a 170 x01 variant, round 1 = 138,
    // round 2 finishes on a single D16 (32). The leg used 3 + 1 = 4 darts,
    // so the darts average must be 4.0, not 6.0.
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_170',
      name: '170',
      view: const ViewXXXCheckout(title: '170'),
      getController: (_) => controller,
      params: const {'xxx': 170, 'max': -1, 'end': 5},
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    // Round 1: 138 (T20 T20 D9 = 60+60+18). Three darts.
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('D9');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    expect(controller.remaining, 170 - 138); // 32

    // Round 2: finish 32 on a single D16.
    state.pressDartboard('D16'); // 32
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    expect(controller.wins, 1);
    // Leg used 4 darts total; average over 1 completed leg = 4.0.
    expect(controller.getCurrentStats()['avgDarts'], '4.0');
  });

  testWidgets('bust mid-round leaves the score unchanged for the leg',
      (tester) async {
    // Start at 20; a single T20 (60) busts.
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_bust',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 20, 'max': -1, 'end': 5},
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    // The digit-by-digit input guard prevents entering a score that busts,
    // so a 60 turn is rejected and the leg score stays at 20 (no win).
    state.pressDartboard('T20'); // 60 > 20
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    expect(controller.wins, 0);
    expect(controller.remaining, 20); // unchanged: bust/rejected
  });
}
