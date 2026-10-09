import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/dart_target.dart';
import 'package:dart/services/drill_service.dart';
import 'package:dart/services/throw_log_model.dart';
import 'package:dart/services/weakness_service.dart';

LoggedDart _d(int seg, String ring, DartTarget t) =>
    LoggedDart(segment: seg, ring: ring, value: 0, target: t);

List<LoggedDart> _aimT(int seg, {required int total, required int hits}) {
  final t = DartTarget.triple(seg);
  return [
    for (int i = 0; i < hits; i++) _d(seg, 'triple', t),
    for (int i = 0; i < total - hits; i++) _d(seg, 'single', t),
  ];
}

void main() {
  final svc = DrillService(weakness: const WeaknessService(minAttempts: 3));

  test('empty data -> empty drill', () {
    expect(svc.suggestDrill(const []), isEmpty);
  });

  test('suggests weakest targets worst-first with labels + hit rate', () {
    final darts = <LoggedDart>[
      ..._aimT(20, total: 5, hits: 4), // 80%
      ..._aimT(19, total: 5, hits: 1), // 20% worst
    ];
    final drill = svc.suggestDrill(darts, count: 3);
    expect(drill.first.label, 'T19');
    expect(drill.first.hitRate, closeTo(0.2, 1e-9));
    expect(drill.map((s) => s.label), containsAll(['T19', 'T20']));
  });

  test('label formats triple/double/single/bull', () {
    final darts = [
      ..._aimT(20, total: 3, hits: 0),
      for (int i = 0; i < 3; i++)
        _d(16, 'single', const DartTarget.double_(16)),
      for (int i = 0; i < 3; i++)
        _d(25, 'miss', const DartTarget.bull()),
    ];
    final labels = svc.suggestDrill(darts, count: 5).map((s) => s.label).toSet();
    expect(labels.contains('T20'), isTrue);
    expect(labels.contains('D16'), isTrue);
    expect(labels.contains('Bull'), isTrue);
  });
}
