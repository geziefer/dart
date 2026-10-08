import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/scolia_dartboard.dart';
import 'package:dart/services/throw_log_service.dart';

import 'scolia_ui_test.mocks.dart';

MockGetStorage _freshStorage() {
  final s = MockGetStorage();
  when(s.read(any)).thenReturn(null);
  when(s.write(any, any)).thenAnswer((_) async {});
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(2000, 1400);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('throws are captured and flushed to the log on dispose',
      (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'CR_test_log',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ));

    // Real throw-log service backed by injected in-memory storage.
    final log = ThrowLogService(storage: _freshStorage())..load();

    await tester.pumpWidget(
      Provider<ThrowLogService>.value(
        value: log,
        child: MaterialApp(
          home: Scaffold(
            body: ScoliaDartboard(
              controller: controller,
              simulator: true,
              gameId: 'CR_test_log',
            ),
          ),
        ),
      ),
    );

    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;

    // Throw and submit two turns.
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    state.pressDartboard('T20');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    state.pressDartboard('T19');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    // Not flushed yet (flush happens on dispose).
    expect(log.sessionCount, 0);

    // Replace the widget to dispose the dartboard -> flush.
    await tester.pumpWidget(
      Provider<ThrowLogService>.value(
        value: log,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pump();

    // One session logged, with all four darts, from Scolia.
    expect(log.sessionCount, 1);
    final session = log.allSessions.single;
    expect(session.gameId, 'CR_test_log');
    expect(session.fromScolia, isTrue);
    expect(session.darts.length, 4); // T20 T20 T20 + T19
    expect(log.dartsForGame('CR_test_log').length, 4);
  });

  testWidgets('no game id -> nothing logged', (tester) async {
    final controller = ControllerXXXCheckout.forTesting(_freshStorage());
    controller.init(MenuItem(
      id: 'nolog',
      name: 'x01',
      view: const ViewXXXCheckout(title: 'x01'),
      getController: (_) => controller,
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ));
    final log = ThrowLogService(storage: _freshStorage())..load();

    await tester.pumpWidget(
      Provider<ThrowLogService>.value(
        value: log,
        child: MaterialApp(
          home: Scaffold(
            // gameId omitted -> capture disabled.
            body: ScoliaDartboard(controller: controller, simulator: true),
          ),
        ),
      ),
    );
    final state =
        tester.state(find.byType(ScoliaDartboard)) as DartboardController;
    state.pressDartboard('T20');
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();

    await tester.pumpWidget(
      Provider<ThrowLogService>.value(
        value: log,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pump();

    expect(log.sessionCount, 0);
  });
}
