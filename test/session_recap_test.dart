import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/services/summary_service.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/widget/menu.dart';

@GenerateMocks([GetStorage])
import 'session_recap_test.mocks.dart';

void main() {
  group('SummaryService.createRecapLines', () {
    test('session + best + recent average, integer formatting', () {
      final lines = SummaryService.createRecapLines(
          value: 42, best: 50, recentAvg: 40.4);
      expect(lines.length, 3);
      expect(lines[0].label, 'Diese Session');
      expect(lines[0].value, '42');
      expect(lines[1].label, 'Bestwert');
      expect(lines[1].value, '50');
      expect(lines[2].label, 'Ø letzte');
      expect(lines[2].value, '40'); // rounded (decimal=false)
    });

    test('one-decimal formatting when decimal=true', () {
      final lines = SummaryService.createRecapLines(
          value: 3.25, best: 4.0, recentAvg: 3.1, decimal: true);
      expect(lines[0].value, '3.3');
      expect(lines[2].value, '3.1');
    });

    test('omits best / recent average when null (first ever game)', () {
      final lines = SummaryService.createRecapLines(value: 10);
      expect(lines.length, 1);
      expect(lines.single.label, 'Diese Session');
    });
  });

  group('recordHighscore populates lastSessionRecap', () {
    // A real in-memory box so result history + highscore round-trip.
    testWidgets('recap reflects prior best/average, not current', (tester) async {
      final box = MockGetStorage();
      final store = <String, dynamic>{};
      when(box.read(any)).thenAnswer((i) => store[i.positionalArguments[0]]);
      when(box.write(any, any)).thenAnswer((i) async =>
          store[i.positionalArguments[0]] = i.positionalArguments[1]);

      final c = ControllerShootx.forTesting(box);
      c.init(MenuItem(
        id: '99x20',
        name: 'x',
        view: const SizedBox.shrink(),
        getController: (_) => throw UnimplementedError(),
        params: const {'x': 20, 'max': 33},
      ));

      // First game: no prior history/best -> only "Diese Session".
      c.recordHighscore(30);
      expect(c.lastSessionRecap.first.value, '30');
      expect(c.lastSessionRecap.length, 1);

      // Second game: prior best 30, prior avg 30 -> three lines.
      c.recordHighscore(40);
      expect(c.lastSessionRecap.length, 3);
      expect(c.lastSessionRecap[0].value, '40'); // this session
      expect(c.lastSessionRecap[1].value, '30'); // prior best
    });
  });
}
