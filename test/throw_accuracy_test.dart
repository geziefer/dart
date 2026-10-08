import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/dart_target.dart';
import 'package:dart/services/throw_accuracy.dart';
import 'package:dart/services/throw_log_model.dart';

LoggedDart _dart({
  required int segment,
  String ring = 'triple',
  int value = 60,
  double? x,
  double? y,
  bool isOuterSingle = true,
  DartTarget? target,
}) =>
    LoggedDart(
      segment: segment,
      ring: ring,
      value: value,
      x: x,
      y: y,
      isOuterSingle: isOuterSingle,
      target: target,
    );

void main() {
  group('DartTarget geometry', () {
    test('bull target centre is the origin', () {
      expect(const DartTarget.bull().center, const Point<double>(0, 0));
    });

    test('T20 centre is near the top (y positive, x ~0)', () {
      final c = const DartTarget.triple(20).center;
      expect(c.x.abs() < 1e-6, isTrue);
      expect(c.y, closeTo(BoardGeometry.trebleMidR, 1e-6));
    });

    test('sectorsAwayFrom wraps around the 20-ring', () {
      // 20 and 1 are adjacent (1 sector); 20 and 5 are adjacent the other way.
      expect(const DartTarget.triple(20).sectorsAwayFrom(1), 1);
      expect(const DartTarget.triple(20).sectorsAwayFrom(5), 1);
      expect(const DartTarget.triple(20).sectorsAwayFrom(20), 0);
    });
  });

  group('ThrowAccuracy', () {
    test('no darts with targets -> no data', () {
      final acc = ThrowAccuracy.compute([
        _dart(segment: 20, x: 0, y: 100), // no target
      ]);
      expect(acc.hasData, isFalse);
      expect(acc.meanDistanceMm, isNull);
    });

    test('mean distance to target is computed from coordinates', () {
      final t = const DartTarget.triple(20);
      final c = t.center;
      // Two darts: one exactly on target (0 mm), one 10 mm away in x.
      final acc = ThrowAccuracy.compute([
        _dart(segment: 20, x: c.x, y: c.y, target: t),
        _dart(segment: 20, x: c.x + 10, y: c.y, target: t),
      ]);
      expect(acc.consideredDarts, 2);
      expect(acc.meanDistanceMm, closeTo(5.0, 1e-6)); // (0 + 10)/2
      expect(acc.stdDistanceMm, isNotNull);
    });

    test('darts >= 2 sectors from target are excluded', () {
      final t = const DartTarget.triple(20);
      final c = t.center;
      final acc = ThrowAccuracy.compute([
        _dart(segment: 20, x: c.x, y: c.y, target: t), // on target
        _dart(segment: 3, x: 0, y: -100, target: t), // opposite wedge -> excluded
      ]);
      expect(acc.consideredDarts, 1);
      expect(acc.meanDistanceMm, closeTo(0.0, 1e-6));
    });

    test('directional bias points toward the offset (clock position)', () {
      final t = const DartTarget.triple(20); // centre near top
      final c = t.center;
      // Darts land consistently to the right of target (+x) -> 3 o'clock.
      final acc = ThrowAccuracy.compute([
        _dart(segment: 20, x: c.x + 12, y: c.y, target: t),
        _dart(segment: 20, x: c.x + 8, y: c.y, target: t),
      ]);
      expect(acc.biasMagnitudeMm, closeTo(10.0, 1e-6));
      expect(acc.biasClock, 3); // +x = 3 o'clock
    });

    test('outer/inner single share from isOuterSingle', () {
      final t = const DartTarget.outerSingle(20);
      final acc = ThrowAccuracy.compute([
        _dart(segment: 20, ring: 'single', value: 20, isOuterSingle: true, target: t),
        _dart(segment: 20, ring: 'single', value: 20, isOuterSingle: true, target: t),
        _dart(segment: 20, ring: 'single', value: 20, isOuterSingle: false, target: t),
      ]);
      expect(acc.singleCount, 3);
      expect(acc.outerSingleShare, closeTo(2 / 3, 1e-9));
    });

    test('single darts without coordinates still count for the share', () {
      final t = const DartTarget.outerSingle(20);
      final acc = ThrowAccuracy.compute([
        _dart(segment: 20, ring: 'single', value: 20, isOuterSingle: true, target: t),
      ]);
      expect(acc.singleCount, 1);
      expect(acc.outerSingleShare, 1.0);
      expect(acc.consideredDarts, 0); // no coords -> no distance
    });
  });
}
