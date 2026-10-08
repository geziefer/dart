import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/view/view_rtcx.dart';
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
    // Tap the last "T20" button (now shows sector label, not score).
    await tester.tap(find.text('T20').last);
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

  testWidgets(
      'post-submit correction: fix a dart in the last round == correct submission',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_postcorr',
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

    // Submit a 180 round and take out (turn committed).
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    expect(controller.remaining, 501 - 180);

    // The committed darts stay on screen. Tap the 3rd committed dart to start
    // post-submit correction (undoes the round + reopens it for editing).
    await tester.tap(find.text('T20').last);
    await tester.pump();
    // Round was undone, so the score is back to the start.
    expect(controller.remaining, 501);

    // Correct the selected (3rd) dart to T19, then confirm with the check icon.
    state.pressDartboard('T19'); // 57
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check)); // re-submit corrected turn
    await tester.pump();

    // 60 + 60 + 57 = 177 — identical to having thrown T20 T20 T19 originally.
    expect(controller.remaining, 501 - 177);
  });

  testWidgets(
      'post-submit correction is not offered without an undo callback',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'test_noundo',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ));
    // No onUndoRound wired.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScoliaDartboard(controller: controller, simulator: true),
      ),
    ));
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    expect(controller.remaining, 501 - 180);

    // Tapping a committed dart does nothing (button disabled, no undo).
    await tester.tap(find.text('T20').last);
    await tester.pump();
    expect(controller.remaining, 501 - 180); // unchanged — no correction started
  });

  testWidgets(
      'post-submit correction works for a count-based game (RTCS)',
      (tester) async {
    final controller = ControllerRTCX.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'rtcs',
      name: 'RTCS',
      view: const ViewRTCX(title: 'RTCS'),
      getController: (_) => controller,
      params: const {'max': 10},
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

    // Throw S1 S2 S3: sequential advancement 1->2->3->4 (currentNumber = 4).
    state.pressDartboard('S1');
    state.pressDartboard('S2');
    state.pressDartboard('S3');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    expect(controller.getCurrentNumber(), 4);

    // Correct the 2nd committed dart (S2) to a miss. Equivalent to S1 miss S3:
    // S1 hits target 1 (->2), miss at 2 (no advance), S3 vs target 2 (no) => 2.
    await tester.tap(find.text('S2'));
    await tester.pump();
    expect(controller.getCurrentNumber(), 1); // round undone, back to start
    await tester.tap(find.byIcon(Icons.block)); // correct selected dart to miss
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check)); // re-submit corrected turn
    await tester.pump();

    expect(controller.getCurrentNumber(), 2);
  });
}
