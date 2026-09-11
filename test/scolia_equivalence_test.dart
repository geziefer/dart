import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/controller/controller_acrossboard.dart';
import 'package:dart/controller/controller_bigts.dart';
import 'package:dart/controller/controller_bobs27.dart';
import 'package:dart/controller/controller_creditfinish.dart';
import 'package:dart/controller/controller_cricket.dart';
import 'package:dart/controller/controller_doublepath.dart';
import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_killbull.dart';
import 'package:dart/controller/controller_planhit.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_twodarts.dart';
import 'package:dart/controller/controller_updown.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:dart/view/view_acrossboard.dart';
import 'package:dart/view/view_bigts.dart';
import 'package:dart/view/view_bobs27.dart';
import 'package:dart/view/view_creditfinish.dart';
import 'package:dart/view/view_cricket.dart';
import 'package:dart/view/view_doublepath.dart';
import 'package:dart/view/view_halfit.dart';
import 'package:dart/view/view_killbull.dart';
import 'package:dart/view/view_planhit.dart';
import 'package:dart/view/view_rtcx.dart';
import 'package:dart/view/view_shootx.dart';
import 'package:dart/view/view_twodarts.dart';
import 'package:dart/view/view_updown.dart';
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

  group('Cricket (H1)', () {
    ControllerCricket make() {
      final s = MockGetStorage();
      when(s.read(any)).thenReturn(null);
      when(s.write(any, any)).thenAnswer((_) async {});
      final c = ControllerCricket.forTesting(s);
      c.init(MenuItem(
        id: 'test_cr',
        name: 'Cricket',
        view: const ViewCricket(title: 'Cricket'),
        getController: (_) => c,
        params: const {},
      ));
      return c;
    }

    test('T20 counts as 3 hits on 20', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('T20')]));
      expect(c.hits[20], 3);
    });

    test('D20 counts as 2 hits on 20', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('D20')]));
      expect(c.hits[20], 2);
    });

    test('S20 counts as 1 hit on 20', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('S20')]));
      expect(c.hits[20], 1);
    });

    test('non-cricket numbers are ignored', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('T10'), t('S5')]));
      expect(c.hits.values.every((v) => v == 0), isTrue);
    });

    test('Bull (inner) counts as 2 hits on 25 (double bull in cricket)', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('Bull')]));
      expect(c.hits[25], 2);
    });

    test('endRound advances round on each turn', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('S20')]));
      expect(c.round, 2);
    });

    test('Scolia path == numpad path for S20 D19 S18', () {
      final numpad = make();
      numpad.pressNumpadButton(20);
      numpad.pressNumpadButton(19);
      numpad.pressNumpadButton(19);
      numpad.pressNumpadButton(18);
      numpad.pressNumpadButton(0);

      final scolia = make();
      scolia.submitScoliaTurn(TurnResult([t('S20'), t('D19'), t('S18')]));

      expect(scolia.hits[20], numpad.hits[20]);
      expect(scolia.hits[19], numpad.hits[19]);
      expect(scolia.hits[18], numpad.hits[18]);
      expect(scolia.round, numpad.round);
    });
  });

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

  // ---- H4 Big Ts ----
  group('BigTs (H4)', () {
    ControllerBigTs make() {
      final c = ControllerBigTs.forTesting(_freshStorage());
      c.init(MenuItem(id: 'bt', name: 'BigTs', view: const ViewBigTs(title: 'BigTs'), getController: (_) => c, params: const {}));
      return c;
    }
    test('T20 in round 1 == pressing 1', () {
      final n = make()..pressNumpadButton(1);
      final s = make()..submitScoliaTurn(TurnResult([t('T20')]));
      expect(s.currentRound, n.currentRound);
      expect(s.hitCounts, n.hitCounts);
    });
    test('non-target (T19 in round 1) == pressing 0', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('T19')]));
      expect(s.hitCounts, n.hitCounts);
    });
    test('round 2 target is T19', () {
      final s = make();
      s.submitScoliaTurn(TurnResult([t('T20')])); // round 1 -> T20
      s.submitScoliaTurn(TurnResult([t('T19')])); // round 2 -> T19
      expect(s.hitCounts[1], 1);
    });
  });

  // ---- H5 Shoot X ----
  group('ShootX (H5)', () {
    ControllerShootx make() {
      final c = ControllerShootx.forTesting(_freshStorage());
      c.init(MenuItem(id: 'sx', name: 'ShootX', view: const ViewShootx(title: 'ShootX'), getController: (_) => c, params: const {'x': 20, 'max': 33}));
      return c;
    }
    test('T20 == pressing 3', () {
      final n = make()..pressNumpadButton(3);
      final s = make()..submitScoliaTurn(TurnResult([t('T20')]));
      expect(s.thrownNumbers, n.thrownNumbers);
    });
    test('D20 S20 == pressing 3 (2+1)', () {
      final n = make()..pressNumpadButton(3);
      final s = make()..submitScoliaTurn(TurnResult([t('D20'), t('S20')]));
      expect(s.thrownNumbers, n.thrownNumbers);
    });
    test('non-target S19 == pressing 0', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('S19')]));
      expect(s.thrownNumbers, n.thrownNumbers);
    });
  });

  // ---- H6 RTC Single ----
  group('RTCX Single (H6)', () {
    ControllerRTCX make() {
      final c = ControllerRTCX.forTesting(_freshStorage());
      c.init(MenuItem(id: 'rtcs', name: 'RTCS', view: const ViewRTCX(title: 'RTCS'), getController: (_) => c, params: const {'max': 10}));
      return c;
    }
    test('S1 advances 1 (single counts)', () {
      final n = make()..pressNumpadButton(1);
      final s = make()..submitScoliaTurn(TurnResult([t('S1')]));
      expect(s.currentNumber, n.currentNumber);
    });
    test('D1 does not advance (double = miss in RTCS)', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('D1')]));
      expect(s.currentNumber, n.currentNumber);
    });
    test('S1 S2 advances 2 sequentially', () {
      final n = make()..pressNumpadButton(2);
      final s = make()..submitScoliaTurn(TurnResult([t('S1'), t('S2')]));
      expect(s.currentNumber, n.currentNumber);
    });
  });

  // ---- H8 Plan Hit ----
  group('PlanHit (H8)', () {
    ControllerPlanHit make(String target) {
      final c = ControllerPlanHit.forTesting(_freshStorage());
      c.init(MenuItem(id: 'ph', name: 'PlanHit', view: const ViewPlanHit(title: 'PlanHit'), getController: (_) => c, params: const {}));
      // Override first target for deterministic testing
      c.targets[0] = target;
      return c;
    }
    test('hitting all 3 in order == pressing 3', () {
      final n = make('4-15-5')..pressNumpadButton(3);
      final s = make('4-15-5')..submitScoliaTurn(TurnResult([t('S4'), t('S15'), t('S5')]));
      expect(s.hitCounts, n.hitCounts);
    });
    test('missing position 1 but hitting 2+3 == pressing 2', () {
      final n = make('4-15-5')..pressNumpadButton(2);
      final s = make('4-15-5')..submitScoliaTurn(TurnResult([t('S20'), t('S15'), t('S5')]));
      expect(s.hitCounts, n.hitCounts);
    });
    test('double of target does not count (singles only)', () {
      final n = make('4-15-5')..pressNumpadButton(0);
      final s = make('4-15-5')..submitScoliaTurn(TurnResult([t('D4'), t('D15'), t('D5')]));
      expect(s.hitCounts, n.hitCounts);
    });
  });

  // ---- H9 Double Path ----
  group('DoublePath (H9)', () {
    ControllerDoublePath make() {
      final c = ControllerDoublePath.forTesting(_freshStorage());
      c.init(MenuItem(id: 'dp', name: 'DP', view: const ViewDoublePath(title: 'DP'), getController: (_) => c, params: const {}));
      return c;
    }
    test('D16 in round 1 (16-8-4) == pressing 1', () {
      final n = make()..pressNumpadButton(1);
      final s = make()..submitScoliaTurn(TurnResult([t('D16')]));
      expect(s.hitCounts, n.hitCounts);
    });
    test('S16 does not count (singles only)', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('S16')]));
      expect(s.hitCounts, n.hitCounts);
    });
  });

  // ---- H10 Across Board ----
  group('AcrossBoard (H10)', () {
    ControllerAcrossBoard make() {
      final c = ControllerAcrossBoard.forTesting(_freshStorage());
      c.init(MenuItem(id: 'ab', name: 'AB', view: const ViewAcrossBoard(title: 'AB'), getController: (_) => c, params: const {'max': 20}));
      return c;
    }
    test('hitting target 1 (D of startNumber) advances 1', () {
      final c = make();
      final target = c.targetSequence[0]; // e.g. 'D20'
      final seg = int.parse(target.substring(1));
      final n = ControllerAcrossBoard.forTesting(_freshStorage());
      n.init(MenuItem(id: 'ab2', name: 'AB', view: const ViewAcrossBoard(title: 'AB'), getController: (_) => n, params: const {'max': 20}));
      n.pressNumpadButton(1);
      c.submitScoliaTurn(TurnResult([DetectedThrow.fromSegment(seg, DartRing.double)]));
      expect(c.currentTargetIndex, n.currentTargetIndex);
    });
    test('wrong segment does not advance', () {
      final c = make();
      final before = c.currentTargetIndex;
      c.submitScoliaTurn(TurnResult([t('S5')]));
      expect(c.currentTargetIndex, before);
    });
  });

  // ---- H11 Half It ----
  group('HalfIt (H11)', () {
    ControllerHalfit make() {
      final c = ControllerHalfit.forTesting(_freshStorage());
      c.init(MenuItem(id: 'hi', name: 'HI', view: const ViewHalfit(title: 'HI'), getController: (_) => c, params: const {'max': -1}));
      return c;
    }
    test('round 15: T15 scores 45 == typing 45 + enter', () {
      final n = make()..pressNumpadButton(4)..pressNumpadButton(5)..pressNumpadButton(-1);
      final s = make()..submitScoliaTurn(TurnResult([t('T15')]));
      expect(s.scores, n.scores);
      expect(s.totalScore, n.totalScore);
    });
    test('round 15: non-15 segment scores 0 (halving)', () {
      final n = make()..pressNumpadButton(0)..pressNumpadButton(-1);
      final s = make()..submitScoliaTurn(TurnResult([t('T20')]));
      expect(s.totalScore, n.totalScore);
    });
  });

  // ---- H12 10 Up 1 Down ----
  group('UpDown (H12)', () {
    ControllerUpDown make() {
      final c = ControllerUpDown.forTesting(_freshStorage());
      c.init(MenuItem(id: 'ud', name: 'UD', view: const ViewUpDown(title: 'UD'), getController: (_) => c, params: const {}));
      return c;
    }
    test('finishing 50 on inner bull (Bull=50) == pressing yes(1)', () {
      final n = make()..pressNumpadButton(1);
      // Bull (inner bull) = 50 exactly == currentTarget (50). Last dart is innerBull → success.
      final s = make()..submitScoliaTurn(TurnResult([t('Bull')]));
      expect(s.successCount, n.successCount);
    });
    test('not finishing == pressing no(0)', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('T20')])); // 60 != 50
      expect(s.successCount, n.successCount);
    });
  });

  // ---- H13 2 Darts ----
  group('TwoDarts (H13)', () {
    ControllerTwoDarts make() {
      final c = ControllerTwoDarts.forTesting(_freshStorage());
      c.init(MenuItem(id: 'td', name: 'TD', view: const ViewTwoDarts(title: 'TD'), getController: (_) => c, params: const {}));
      return c;
    }
    test('S11 + DB (=61) == pressing yes(1)', () {
      final n = make()..pressNumpadButton(1);
      final s = make()..submitScoliaTurn(TurnResult([t('S11'), t('Bull')]));
      expect(s.successCount, n.successCount);
    });
    test('3 darts even if sum correct == pressing no(0)', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('S11'), t('Bull'), t('S1')]));
      expect(s.successCount, n.successCount);
    });
    test('S11 + D5 (wrong finish, not inner bull) == no', () {
      final n = make()..pressNumpadButton(0);
      final s = make()..submitScoliaTurn(TurnResult([t('S1'), t('D5')])); // 1+10 != 61
      expect(s.successCount, n.successCount);
    });
  });

  // ---- H2 Kill Bull ----
  group('KillBull (H2)', () {
    ControllerKillBull make() {
      final c = ControllerKillBull.forTesting(_freshStorage());
      c.init(MenuItem(id: 'kb', name: 'KB', view: const ViewKillBull(title: 'KB'), getController: (_) => c, params: const {}));
      return c;
    }
    test('inner bull (DB) == pressing 2', () {
      final n = make()..pressNumpadButton(2);
      final s = make()..submitScoliaTurn(TurnResult([t('Bull')]));
      expect(s.roundScores, n.roundScores);
    });
    test('outer bull (SB) == pressing 1', () {
      final n = make()..pressNumpadButton(1);
      final s = make()..submitScoliaTurn(TurnResult([t('25')]));
      expect(s.roundScores, n.roundScores);
    });
    test('3x inner bull == pressing 6', () {
      final n = make()..pressNumpadButton(6);
      final s = make()..submitScoliaTurn(TurnResult([t('Bull'), t('Bull'), t('Bull')]));
      expect(s.roundScores, n.roundScores);
    });
  });

  // ---- H16 Credit Finish ----
  group('CreditFinish (H16)', () {
    ControllerCreditFinish make() {
      final c = ControllerCreditFinish.forTesting(_freshStorage());
      c.init(MenuItem(id: 'cf', name: 'CF', view: const ViewCreditFinish(title: 'CF'), getController: (_) => c, params: const {}));
      return c;
    }
    test('phase 1: T20 T20 T20 (180) == typing 180 + enter', () {
      final n = make()..pressNumpadButton(1)..pressNumpadButton(8)..pressNumpadButton(0)..pressNumpadButton(-1);
      final s = make()..submitScoliaTurn(TurnResult([t('T20'), t('T20'), t('T20')]));
      expect(s.scores, n.scores);
      expect(s.credits, n.credits);
    });
    test('score < 57 is auto-miss (no credits)', () {
      final c = make();
      c.submitScoliaTurn(TurnResult([t('S20')])); // 20 < 57
      expect(c.missCount, 1);
    });
  });
}
