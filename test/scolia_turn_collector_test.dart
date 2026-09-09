import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:dart/scolia/turn_collector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<TurnResult> completed;
  late TurnCollector collector;

  setUp(() {
    completed = <TurnResult>[];
    collector = TurnCollector(onTurnComplete: completed.add);
  });

  DetectedThrow t(String sector) => SectorParser.parse(sector);

  test('three darts then takeout closes turn with total', () {
    collector.addThrow(t('T20'));
    collector.addThrow(t('T20'));
    collector.addThrow(t('T20'));
    expect(completed, isEmpty); // not closed until takeout by default
    collector.onTakeoutFinished(falseTakeout: false);
    expect(completed, hasLength(1));
    expect(completed.first.total, 180);
    expect(completed.first.dartCount, 3);
  });

  test('turn with fewer than 3 darts (checkout) closes on takeout', () {
    collector.addThrow(t('T20'));
    collector.addThrow(t('D20'));
    collector.onTakeoutFinished(falseTakeout: false);
    expect(completed, hasLength(1));
    expect(completed.first.dartCount, 2);
    expect(completed.first.total, 100);
  });

  test('false takeout does not close the turn', () {
    collector.addThrow(t('T20'));
    collector.onTakeoutFinished(falseTakeout: true);
    expect(completed, isEmpty);
    expect(collector.pending, hasLength(1));
    // A subsequent real takeout still closes it.
    collector.onTakeoutFinished(falseTakeout: false);
    expect(completed, hasLength(1));
  });

  test('empty turn (no darts) does not emit on takeout', () {
    collector.onTakeoutFinished(falseTakeout: false);
    expect(completed, isEmpty);
  });

  test('darts ignored while in takeout phase', () {
    collector.onTakeoutStarted();
    collector.addThrow(t('T20')); // should be ignored
    expect(collector.pending, isEmpty);
    // Back to throwing after takeout finishes (no darts -> no emit)
    collector.onTakeoutFinished(falseTakeout: false);
    expect(completed, isEmpty);
    collector.addThrow(t('S5'));
    expect(collector.pending, hasLength(1));
  });

  test('buffer will not exceed maxDartsPerTurn', () {
    collector.addThrow(t('T20'));
    collector.addThrow(t('T20'));
    collector.addThrow(t('T20'));
    collector.addThrow(t('T20')); // 4th ignored
    expect(collector.pending, hasLength(3));
  });

  test('reset clears buffer without emitting', () {
    collector.addThrow(t('T20'));
    collector.reset();
    expect(collector.pending, isEmpty);
    expect(completed, isEmpty);
  });

  test('autoCloseAtMaxDarts emits at 3 without takeout', () {
    final auto = TurnCollector(
      autoCloseAtMaxDarts: true,
      onTurnComplete: completed.add,
    );
    auto.addThrow(t('T20'));
    auto.addThrow(t('T20'));
    auto.addThrow(t('T20'));
    expect(completed, hasLength(1));
    expect(completed.first.total, 180);
  });

  test('miss darts (bounceout/None) count as darts with value 0', () {
    collector.addThrow(t('T20'));
    collector.addThrow(SectorParser.parse('None'));
    collector.addThrow(SectorParser.parse('T20', bounceout: true));
    collector.onTakeoutFinished(falseTakeout: false);
    expect(completed.first.dartCount, 3);
    expect(completed.first.total, 60);
  });

  test('setPhase throwing re-enables input', () {
    collector.setPhase(BoardPhase.takeout);
    collector.addThrow(t('T20'));
    expect(collector.pending, isEmpty);
    collector.setPhase(BoardPhase.throwing);
    collector.addThrow(t('T20'));
    expect(collector.pending, hasLength(1));
  });
}
