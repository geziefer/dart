import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dart/interfaces/dartboard_controller.dart';
import 'package:dart/scolia/mock_scolia_source.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:dart/scolia/scolia_event_source.dart';
import 'package:dart/scolia/scolia_service.dart';
import 'package:dart/scolia/scolia_settings.dart';
import 'package:dart/view/view_scolia_monitor.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/widget/fullcircle.dart';

class _NoInput implements DartboardController {
  @override
  void pressDartboard(String value) {}
}

/// Minimal ScoliaService for tests — wraps a MockScoliaSource.
class _TestScoliaService extends ScoliaService {
  _TestScoliaService(this._mock)
      : super(settings: ScoliaSettings());

  final MockScoliaSource _mock;

  @override
  ScoliaEventSource? get source => _mock;

  @override
  bool get isSimulator => false;

  void addToLog(ScoliaMessage msg) {
    messageLog.insert(0, msg);
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(2400, 1400);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Widget board(String? highlight) => MaterialApp(
        home: Scaffold(
          body: FullCircle(
            controller: _NoInput(),
            radius: 200,
            highlightSector: highlight,
            arcSections: [
              ArcSection(startPercent: 0.2),
              ArcSection(startPercent: 0.35),
              ArcSection(startPercent: 0.55),
              ArcSection(startPercent: 0.8),
            ],
          ),
        ),
      );

  testWidgets('FullCircle renders with various highlight sectors (no error)',
      (tester) async {
    for (final s in [null, 'T20', 'S1', 'D16', '25', 'Bull', 'None']) {
      await tester.pumpWidget(board(s));
      await tester.pump();
      expect(find.byType(FullCircle), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Monitor logs a THROW_DETECTED and flashes the board',
      (tester) async {
    final mock = MockScoliaSource();
    final svc = _TestScoliaService(mock);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<ScoliaService>.value(
        value: svc,
        child: const ViewScoliaMonitor(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 10));

    // Board sends a detected T20.
    mock.throwSector('T20');
    svc.addToLog(ThrowDetectedMessage(
      null,
      detectedThrow: SectorParser.parse('T20'),
      sector: 'T20',
    ));
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.textContaining('THROW_DETECTED'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('Monitor is display-only (no input/throw buttons)',
      (tester) async {
    final svc = _TestScoliaService(MockScoliaSource());
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<ScoliaService>.value(
        value: svc,
        child: const ViewScoliaMonitor(),
      ),
    ));
    await tester.pump();
    // The old simulator control buttons must be gone.
    expect(find.widgetWithText(ElevatedButton, 'T20'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Takeout start'), findsNothing);
    // Let any pending flash timer expire before the widget is torn down.
    await tester.pump(const Duration(milliseconds: 700));
  });
}
