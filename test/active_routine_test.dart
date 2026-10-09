import 'package:flutter_test/flutter_test.dart';

import 'package:dart/services/active_routine.dart';
import 'package:dart/services/routine_generator.dart';

void main() {
  test('progression through games then auto-ends', () {
    final ar = ActiveRoutine();
    expect(ar.isActive, isFalse);

    ar.start(const Routine(['A', 'B', 'C']));
    expect(ar.isActive, isTrue);
    expect(ar.nextGameId, 'A');
    expect(ar.position, 1);
    expect(ar.total, 3);

    ar.advance();
    expect(ar.nextGameId, 'B');
    expect(ar.position, 2);

    ar.advance();
    expect(ar.nextGameId, 'C');

    ar.advance();
    expect(ar.isActive, isFalse);
    expect(ar.nextGameId, isNull);
  });

  test('cancel ends the routine', () {
    final ar = ActiveRoutine()..start(const Routine(['A', 'B']));
    ar.cancel();
    expect(ar.isActive, isFalse);
  });

  test('notifies on start/advance/cancel', () {
    final ar = ActiveRoutine();
    var n = 0;
    ar.addListener(() => n++);
    ar.start(const Routine(['A']));
    ar.advance(); // auto-ends
    expect(n, 2);
  });
}
