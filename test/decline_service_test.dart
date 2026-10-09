import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/decline_service.dart';

void main() {
  const svc = DeclineService(window: 3, margin: 0.05);

  test('insufficient history -> not declining', () {
    expect(svc.isDeclining([60, 55], higherIsBetter: true), isFalse);
  });

  test('higher-is-better: recent lower average -> declining', () {
    // prev [60,60,60]=60, recent [40,40,40]=40 -> 33% worse.
    expect(
        svc.isDeclining([60, 60, 60, 40, 40, 40], higherIsBetter: true), isTrue);
  });

  test('higher-is-better: recent higher average -> not declining', () {
    expect(
        svc.isDeclining([40, 40, 40, 60, 60, 60], higherIsBetter: true),
        isFalse);
  });

  test('lower-is-better: recent higher average -> declining', () {
    // Darts count: prev 20, recent 28 -> worse (more darts).
    expect(
        svc.isDeclining([20, 20, 20, 28, 28, 28], higherIsBetter: false),
        isTrue);
  });

  test('flat within margin -> not declining', () {
    expect(
        svc.isDeclining([60, 60, 60, 59, 60, 59], higherIsBetter: true),
        isFalse);
  });

  test('works with exactly window+1 values', () {
    // window=3 needs 4+. prev = [100] (1 value), recent = [80,80,80]=80.
    expect(svc.isDeclining([100, 80, 80, 80], higherIsBetter: true), isTrue);
  });
}
