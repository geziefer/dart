import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/dart_target.dart';
import 'package:dart/services/throw_log_model.dart';
import 'package:dart/services/weakness_service.dart';

LoggedDart _d(int seg, String ring, {DartTarget? target}) =>
    LoggedDart(segment: seg, ring: ring, value: 0, target: target);

void main() {
  const svc = WeaknessService(minAttempts: 3);

  List<LoggedDart> aimT(int seg, {required int total, required int hits}) {
    // `total` darts aimed at triple(seg); `hits` of them hit the triple, the
    // rest land as singles of the same segment (1 sector away => not excluded).
    final t = DartTarget.triple(seg);
    return [
      for (int i = 0; i < hits; i++) _d(seg, 'triple', target: t),
      for (int i = 0; i < total - hits; i++) _d(seg, 'single', target: t),
    ];
  }

  test('summarise groups by target and counts hits', () {
    final darts = aimT(20, total: 4, hits: 3);
    final s = svc.summarise(darts);
    expect(s.length, 1);
    expect(s.first.attempts, 4);
    expect(s.first.hits, 3);
    expect(s.first.hitRate, closeTo(0.75, 1e-9));
  });

  test('ignores darts without a target', () {
    final darts = [_d(20, 'triple'), _d(5, 'single')];
    expect(svc.summarise(darts), isEmpty);
  });

  test('excludes darts >= 2 sectors from target', () {
    final t = DartTarget.triple(20);
    // 20 and 3 are opposite (far) -> excluded; only the on-target dart counts.
    final darts = [
      _d(20, 'triple', target: t),
      _d(3, 'single', target: t),
    ];
    final s = svc.summarise(darts);
    expect(s.single.attempts, 1);
  });

  test('weakest ranks lowest hit-rate first, respecting minAttempts', () {
    final darts = <LoggedDart>[
      ...aimT(20, total: 5, hits: 4), // 0.8
      ...aimT(19, total: 5, hits: 1), // 0.2  (weakest)
      ...aimT(18, total: 5, hits: 3), // 0.6
      ...aimT(17, total: 2, hits: 0), // below minAttempts -> excluded
    ];
    final worst = svc.weakest(darts, n: 2);
    expect(worst.length, 2);
    expect(worst[0].target.segment, 19); // lowest hit rate
    expect(worst[1].target.segment, 18);
    // 17 excluded (only 2 attempts).
    expect(worst.any((w) => w.target.segment == 17), isFalse);
  });

  test('bull target hit detection (outer bull counts for bull)', () {
    const t = DartTarget.bull();
    final darts = [
      _d(25, 'innerBull', target: t),
      _d(25, 'outerBull', target: t),
      _d(25, 'miss', target: t),
    ];
    final s = svc.summarise(darts);
    expect(s.single.attempts, 3);
    expect(s.single.hits, 2); // inner + outer bull both count
  });
}
