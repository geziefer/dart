import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/scolia_controller.dart';
import 'package:dart/services/dart_target.dart';
import 'package:dart/widget/menu.dart';

import 'package:dart/controller/controller_killbull.dart';
import 'package:dart/controller/controller_speedbull.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_bobs27.dart';
import 'package:dart/controller/controller_bigts.dart';
import 'package:dart/controller/controller_doublepath.dart';
import 'package:dart/controller/controller_planhit.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_acrossboard.dart';
import 'package:dart/controller/controller_twodarts.dart';
import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';

@GenerateMocks([GetStorage])
import 'target_reporting_test.mocks.dart';

MockGetStorage _storage() {
  final s = MockGetStorage();
  when(s.read(any)).thenReturn(null);
  when(s.write(any, any)).thenAnswer((_) async {});
  return s;
}

MenuItem _item(String id, Map<String, dynamic> params) => MenuItem(
      id: id,
      name: id,
      view: const SizedBox.shrink(),
      getController: (_) => throw UnimplementedError(),
      params: params,
    );

DetectedThrow _d(int segment, DartRing ring) =>
    DetectedThrow.fromSegment(segment, ring);

List<DartTarget?> _targets(dynamic controller, List<DetectedThrow> darts) {
  controller.submitScoliaTurn(TurnResult(darts));
  return (controller as AimTargetReporting).targetsForLastTurn();
}

void main() {
  test('killbull: every dart targets the bull', () {
    final c = ControllerKillBull.forTesting(_storage())
      ..init(_item('KB', const {}));
    final t = _targets(
        c, [_d(25, DartRing.innerBull), _d(25, DartRing.outerBull)]);
    expect(t.length, 2);
    expect(t.every((x) => x!.ring == TargetRing.innerBull), isTrue);
  });

  test('speedbull: every dart targets the bull', () {
    final c = ControllerSpeedBull.forTesting(_storage())
      ..init(_item('SB', const {'duration': 60}));
    final t = _targets(c, [_d(25, DartRing.innerBull)]);
    expect(t.single!.ring, TargetRing.innerBull);
  });

  test('shootx: scoring on x -> triple(x)', () {
    final c = ControllerShootx.forTesting(_storage())
      ..init(_item('99x20', const {'x': 20, 'max': 33}));
    final t = _targets(c, [_d(20, DartRing.triple), _d(20, DartRing.single)]);
    expect(t.length, 2);
    expect(
        t.every((x) => x!.ring == TargetRing.triple && x.segment == 20), isTrue);
  });

  test('bobs27: round 1 targets double of 1', () {
    final c = ControllerBobs27.forTesting(_storage())
      ..init(_item('B27', const {}));
    final t = _targets(c, [_d(1, DartRing.double)]);
    expect(t.first!.ring, TargetRing.double_);
    expect(t.first!.segment, 1);
  });

  test('bigts: darts target T20, T19, T18 in order', () {
    final c = ControllerBigTs.forTesting(_storage())
      ..init(_item('BT', const {}));
    final t = _targets(c, [
      _d(20, DartRing.triple),
      _d(19, DartRing.triple),
      _d(18, DartRing.triple),
    ]);
    expect(t.map((x) => x!.segment).toList(), [20, 19, 18]);
    expect(t.every((x) => x!.ring == TargetRing.triple), isTrue);
  });

  test('doublepath: round 1 targets doubles of 16-8-4', () {
    final c = ControllerDoublePath.forTesting(_storage())
      ..init(_item('DPath', const {}));
    final t = _targets(c, [
      _d(16, DartRing.double),
      _d(8, DartRing.double),
      _d(4, DartRing.double),
    ]);
    expect(t.map((x) => x!.segment).toList(), [16, 8, 4]);
    expect(t.every((x) => x!.ring == TargetRing.double_), isTrue);
  });

  test('planhit: per-dart single targets', () {
    final c = ControllerPlanHit.forTesting(_storage())
      ..init(_item('PLANHIT', const {}));
    final t = _targets(c, [_d(5, DartRing.single), _d(5, DartRing.single)]);
    expect(t.every((x) => x!.ring == TargetRing.single), isTrue);
  });

  test('rtcx (RTCS): dart targets big single of current number', () {
    final c = ControllerRTCX.forTesting(_storage())
      ..init(_item('RTCS', const {'max': 10}));
    final t = _targets(c, [_d(1, DartRing.single)]);
    expect(t.single!.ring, TargetRing.single);
    expect(t.single!.segment, 1);
  });

  test('twodarts: dart1 single (target-50), dart2 bull', () {
    final c = ControllerTwoDarts.forTesting(_storage())
      ..init(_item('2D', const {}));
    final t = _targets(c, [_d(11, DartRing.single), _d(25, DartRing.innerBull)]);
    expect(t[0]!.ring, TargetRing.single);
    expect(t[0]!.segment, 11);
    expect(t[1]!.ring, TargetRing.innerBull);
  });

  test('acrossboard: first dart targets the start number double', () {
    final c = ControllerAcrossBoard.forTesting(_storage())
      ..init(_item('ACROSSBOARD', const {'max': 20}));
    // The sequence starts with D<startNumber>; the number is random but the
    // first aim point is always a double.
    final t = _targets(c, [_d(1, DartRing.single)]);
    expect(t.first, isNotNull);
    expect(t.first!.ring, TargetRing.double_);
  });

  test('halfit: number round targets that number triple', () {
    final c = ControllerHalfit.forTesting(_storage())
      ..init(_item('HI', const {'max': -1}));
    final t = _targets(c, [_d(15, DartRing.triple)]);
    expect(t.single!.ring, TargetRing.triple);
    expect(t.single!.segment, 15);
  });

  group('xxxcheckout double-reached heuristic', () {
    test('scoring phase (large remaining) -> no target', () {
      final c = ControllerXXXCheckout.forTesting(_storage())
        ..init(_item('501x5', const {'xxx': 501, 'max': -1, 'end': 5}));
      final t = _targets(c, [
        _d(20, DartRing.triple),
        _d(20, DartRing.triple),
        _d(20, DartRing.triple),
      ]);
      expect(t.every((x) => x == null), isTrue);
    });

    test('direct double remaining -> double target', () {
      final c = ControllerXXXCheckout.forTesting(_storage())
        ..init(_item('x40', const {'xxx': 40, 'max': -1, 'end': 5}));
      final t = _targets(c, [_d(20, DartRing.double)]);
      expect(t.single!.ring, TargetRing.double_);
      expect(t.single!.segment, 20);
    });
  });
}
