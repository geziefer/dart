import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/services/result_history_service.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/streak_service.dart';

/// In-memory fake storage for one game container.
class _FakeBox implements GetStorage {
  final Map<String, dynamic> _d = {};
  @override
  T? read<T>(String key) => _d[key] as T?;
  @override
  Future<void> write(String key, dynamic value) async => _d[key] = value;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

StorageService _svc(_FakeBox box) => StorageService('g', injectedStorage: box);

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  group('ResultHistoryService', () {
    test('records and reads dated results, date-only', () {
      final box = _FakeBox();
      final svc = ResultHistoryService(_svc(box));
      svc.record(60, when: _d(2026, 1, 1));
      svc.record(45, when: _d(2026, 1, 2));

      final h = svc.getHistory();
      expect(h.length, 2);
      expect(h.first.value, 60);
      expect(h.first.date, _d(2026, 1, 1));
    });

    test('bounds to the newest maxResultHistoryEntries', () {
      final svc = ResultHistoryService(_svc(_FakeBox()));
      for (int i = 0; i < maxResultHistoryEntries + 20; i++) {
        svc.record(i.toDouble(), when: _d(2026, 1, 1));
      }
      final h = svc.getHistory();
      expect(h.length, maxResultHistoryEntries);
      // Oldest 20 dropped: first kept value is 20.
      expect(h.first.value, 20);
    });

    test('playedDates returns distinct days', () {
      final svc = ResultHistoryService(_svc(_FakeBox()));
      svc.record(1, when: DateTime(2026, 1, 1, 10));
      svc.record(2, when: DateTime(2026, 1, 1, 20)); // same day
      svc.record(3, when: _d(2026, 1, 2));
      expect(svc.playedDates(), {_d(2026, 1, 1), _d(2026, 1, 2)});
    });
  });

  group('StreakService', () {
    // Build a StreakService over two games with injected histories.
    StreakService make(Map<String, List<DateTime>> byGame) {
      final boxes = <String, ResultHistoryService>{};
      byGame.forEach((id, dates) {
        final svc = ResultHistoryService(_svc(_FakeBox()));
        for (final d in dates) {
          svc.record(1, when: d);
        }
        boxes[id] = svc;
      });
      return StreakService(byGame.keys.toList(), historyFor: (id) => boxes[id]!);
    }

    test('empty history -> zero streak', () {
      final s = make({'A': []}).compute(today: _d(2026, 1, 10));
      expect(s.currentStreak, 0);
      expect(s.trainedToday, isFalse);
      expect(s.daysThisWeek, 0);
    });

    test('consecutive days ending today', () {
      final s = make({
        'A': [_d(2026, 1, 8), _d(2026, 1, 9), _d(2026, 1, 10)],
      }).compute(today: _d(2026, 1, 10));
      expect(s.trainedToday, isTrue);
      expect(s.currentStreak, 3);
    });

    test('streak counts from yesterday when not trained today', () {
      final s = make({
        'A': [_d(2026, 1, 8), _d(2026, 1, 9)],
      }).compute(today: _d(2026, 1, 10));
      expect(s.trainedToday, isFalse);
      expect(s.currentStreak, 2); // 8th + 9th, ending yesterday
    });

    test('gap breaks the streak', () {
      final s = make({
        'A': [_d(2026, 1, 5), _d(2026, 1, 9), _d(2026, 1, 10)],
      }).compute(today: _d(2026, 1, 10));
      expect(s.currentStreak, 2); // 9th + 10th; 5th is separated by a gap
    });

    test('streak unions across games', () {
      final s = make({
        'A': [_d(2026, 1, 9)],
        'B': [_d(2026, 1, 10)],
      }).compute(today: _d(2026, 1, 10));
      expect(s.currentStreak, 2); // 9th from A, 10th from B
    });

    test('daysThisWeek counts Mon..today distinct days', () {
      // 2026-01-10 is a Saturday; Monday is 2026-01-05.
      final s = make({
        'A': [_d(2026, 1, 5), _d(2026, 1, 7), _d(2026, 1, 10)],
        'B': [_d(2026, 1, 4)], // previous week (Sunday) -> excluded
      }).compute(today: _d(2026, 1, 10));
      expect(s.daysThisWeek, 3);
    });
  });

  test('ResultEntry JSON round-trip', () {
    final e = ResultEntry(date: _d(2026, 3, 4), value: 99);
    final back = ResultEntry.fromJson(
        jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>);
    expect(back.date, _d(2026, 3, 4));
    expect(back.value, 99);
  });
}
