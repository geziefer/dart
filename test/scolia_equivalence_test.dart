import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/controller/controller_bobs27.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:dart/view/view_bobs27.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';

@GenerateMocks([GetStorage])
import 'scolia_equivalence_test.mocks.dart';

MockGetStorage _freshStorage() {
  final s = MockGetStorage();
  when(s.read(any)).thenReturn(null);
  when(s.write(any, any)).thenAnswer((_) async {});
  return s;
}

DetectedThrow t(String sector) => SectorParser.parse(sector);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('xxxcheckout: Scolia turn == numpad entry', () {
    ControllerXXXCheckout make() {
      final c = ControllerXXXCheckout.forTesting(_freshStorage());
      c.init(MenuItem(
        id: 'test_x01',
        name: 'x01',
        view: const ViewXXXCheckout(title: 'x01'),
        getController: (_) => c,
        params: const {'xxx': 501, 'max': -1, 'end': 5},
      ));
      return c;
    }

    test('a 140 turn (T20 T20 S20) equals typing 140 + enter', () {
      final numpad = make();
      // Numpad: type 1,4,0 then enter
      numpad.pressNumpadButton(1);
      numpad.pressNumpadButton(4);
      numpad.pressNumpadButton(0);
      numpad.pressNumpadButton(-1);

      final scolia = make();
      scolia.submitScoliaTurn(TurnResult([t('T20'), t('T20'), t('S20')]));

      expect(scolia.remaining, numpad.remaining);
      expect(scolia.scores, numpad.scores);
      expect(scolia.remainings, numpad.remainings);
      expect(scolia.totalScore, numpad.totalScore);
      expect(scolia.round, numpad.round);
      expect(scolia.remaining, 501 - 140);
    });

    test('a 180 turn (T20 x3) equals typing 180 + enter', () {
      final numpad = make();
      numpad.pressNumpadButton(1);
      numpad.pressNumpadButton(8);
      numpad.pressNumpadButton(0);
      numpad.pressNumpadButton(-1);

      final scolia = make();
      scolia.submitScoliaTurn(TurnResult([t('T20'), t('T20'), t('T20')]));

      expect(scolia.remaining, numpad.remaining);
      expect(scolia.remaining, 501 - 180);
      expect(scolia.scores, numpad.scores);
    });

    test('a turn with a miss (T20 None S20 = 80) equals typing 80', () {
      final numpad = make();
      numpad.pressNumpadButton(8);
      numpad.pressNumpadButton(0);
      numpad.pressNumpadButton(-1);

      final scolia = make();
      scolia.submitScoliaTurn(TurnResult([t('T20'), t('None'), t('S20')]));
      // T20 + None + S20 = 60 + 0 + 20 = 80
      expect(scolia.remaining, numpad.remaining);
      expect(scolia.remaining, 501 - 80);
      expect(scolia.scores, numpad.scores);
    });
  });

  group('bobs27: Scolia turn == numpad hit-count', () {
    ControllerBobs27 make() {
      final c = ControllerBobs27.forTesting(_freshStorage());
      c.init(MenuItem(
        id: 'test_bobs27',
        name: 'Bobs 27',
        view: const ViewBobs27(title: 'Bobs 27'),
        getController: (_) => c,
        params: const {},
      ));
      return c;
    }

    test('two darts on double-1 equals pressing 2 (target 1)', () {
      // First target is 1.
      final numpad = make();
      numpad.pressNumpadButton(2); // 2 hits

      final scolia = make();
      scolia.submitScoliaTurn(TurnResult([t('D1'), t('D1'), t('S1')]));
      // Only the two D1 count as doubles of target 1.

      expect(scolia.totalScore, numpad.totalScore);
      expect(scolia.currentTargetIndex, numpad.currentTargetIndex);
      expect(scolia.successfulRounds, numpad.successfulRounds);
      // 27 + 2 * (1*2) = 31
      expect(scolia.totalScore, 31);
    });

    test('no doubles equals pressing 0 (miss penalty)', () {
      final numpad = make();
      numpad.pressNumpadButton(0);

      final scolia = make();
      // Hits on single-1 and triple-1 are NOT doubles -> 0 counted.
      scolia.submitScoliaTurn(TurnResult([t('S1'), t('T1'), t('S5')]));

      expect(scolia.totalScore, numpad.totalScore);
      expect(scolia.currentTargetIndex, numpad.currentTargetIndex);
      // 27 - (1*2) = 25 (miss penalty = -double)
      expect(scolia.totalScore, 25);
    });

    test('bull round: inner bull counts as double of bull', () {
      // Advance both controllers to the bull target (index 20) identically by
      // scoring one double on each target 1..20 (keeps the game alive).
      final numpad = make();
      final scolia = make();
      for (int i = 1; i <= 20; i++) {
        numpad.pressNumpadButton(1); // 1 double hit on current target
        scolia.submitScoliaTurn(TurnResult([t('D$i')]));
        expect(scolia.currentTargetIndex, numpad.currentTargetIndex);
        expect(scolia.totalScore, numpad.totalScore);
      }
      // Now on bull (index 20). One inner bull = 1 double-of-bull hit.
      final before = numpad.totalScore;
      numpad.pressNumpadButton(1);
      scolia.submitScoliaTurn(TurnResult([t('Bull'), t('25'), t('S5')]));
      // Only inner Bull counts; outer 25 and S5 do not.
      expect(scolia.totalScore, numpad.totalScore);
      // bull double = 50
      expect(numpad.totalScore, before + 50);
    });
  });
}
