import 'package:dart/services/highscore_service.dart';
import 'package:dart/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory StorageService stand-in: avoids needing a real GetStorage backend
/// in unit tests. Only read/write of the highscore JSON string are exercised.
class FakeStorage extends StorageService {
  final Map<String, dynamic> _data = {};

  FakeStorage() : super('test');

  @override
  T? read<T>(String key, {T? defaultValue}) =>
      (_data[key] as T?) ?? defaultValue;

  @override
  bool write<T>(String key, T value) {
    _data[key] = value;
    return true;
  }
}

void main() {
  group('HighscoreEntry', () {
    test('formats date as dd.MM.yyyy', () {
      expect(HighscoreEntry.formatDate(DateTime(2026, 1, 22)), '22.01.2026');
      expect(HighscoreEntry.formatDate(DateTime(2026, 12, 5)), '05.12.2026');
    });

    test('round-trips through JSON', () {
      final e = HighscoreEntry(value: 12, value2: 3.5, date: '01.02.2026');
      final back = HighscoreEntry.fromJson(e.toJson());
      expect(back.value, 12);
      expect(back.value2, 3.5);
      expect(back.date, '01.02.2026');
    });

    test('omits value2 when null', () {
      final e = HighscoreEntry(value: 7, date: '01.02.2026');
      expect(e.toJson().containsKey('value2'), isFalse);
      expect(HighscoreEntry.fromJson(e.toJson()).value2, isNull);
    });
  });

  group('HighscoreConfig formatting', () {
    test('integer vs decimal primary/tie-breaker', () {
      const c = HighscoreConfig(
          higherIsBetter: true, label: 'P', label2: 'Ø', decimal2: true);
      expect(c.formatValue(42.0), '42');
      expect(c.formatValue2(61.47), '61.5');
      expect(c.formatValue2(null), '');
    });

    test('medal formatting', () {
      const c =
          HighscoreConfig(higherIsBetter: true, label: 'M', isMedal: true);
      expect(c.formatValue(0), '🥉');
      expect(c.formatValue(4), '🥇');
      expect(c.formatValue(5), '🥇+');
      expect(c.formatValue(99), '😢');
    });
  });

  group('HighscoreService (higher is better)', () {
    late FakeStorage storage;
    late HighscoreService service;

    setUp(() {
      storage = FakeStorage();
      service = HighscoreService(
          storage, const HighscoreConfig(higherIsBetter: true, label: 'P'));
    });

    test('empty list initially', () {
      expect(service.getHighscores(), isEmpty);
    });

    test('records first entry at rank 1', () {
      final rank = service.recordResult(value: 50, when: DateTime(2026, 1, 1));
      expect(rank, 1);
      expect(service.getHighscores().length, 1);
      expect(service.getHighscores().first.value, 50);
    });

    test('higher value climbs above lower', () {
      service.recordResult(value: 50, when: DateTime(2026, 1, 1));
      final rank = service.recordResult(value: 80, when: DateTime(2026, 1, 2));
      expect(rank, 1);
      final list = service.getHighscores();
      expect(list[0].value, 80);
      expect(list[1].value, 50);
    });

    test('equal value is added but sorts after the existing equal entry', () {
      service.recordResult(value: 50, when: DateTime(2026, 1, 1));
      final rank = service.recordResult(value: 50, when: DateTime(2026, 1, 2));
      expect(rank, 2, reason: 'tie does not beat the earlier equal entry');
      final list = service.getHighscores();
      expect(list[0].date, '01.01.2026');
      expect(list[1].date, '02.01.2026');
    });

    test('keeps only top 10 and rejects a worse 11th', () {
      for (int i = 1; i <= 10; i++) {
        service.recordResult(value: i.toDouble(), when: DateTime(2026, 1, i));
      }
      // Worst present is value 1. A value of 0 must be rejected.
      final rank = service.recordResult(value: 0, when: DateTime(2026, 2, 1));
      expect(rank, isNull);
      expect(service.getHighscores().length, 10);
    });

    test('a better 11th displaces the worst and trims to 10', () {
      for (int i = 1; i <= 10; i++) {
        service.recordResult(value: i.toDouble(), when: DateTime(2026, 1, i));
      }
      final rank = service.recordResult(value: 100, when: DateTime(2026, 2, 1));
      expect(rank, 1);
      final list = service.getHighscores();
      expect(list.length, 10);
      expect(list.first.value, 100);
      // The old worst (value 1) was pushed out.
      expect(list.any((e) => e.value == 1), isFalse);
    });

    test('tie-breaker orders equal primaries', () {
      final s = HighscoreService(
          FakeStorage(),
          const HighscoreConfig(
              higherIsBetter: true, label: 'P', label2: 'T'));
      s.recordResult(value: 50, value2: 2, when: DateTime(2026, 1, 1));
      final rank =
          s.recordResult(value: 50, value2: 9, when: DateTime(2026, 1, 2));
      // Higher tie-breaker wins the equal-primary comparison → rank 1.
      expect(rank, 1);
      expect(s.getHighscores().first.value2, 9);
    });
  });

  group('HighscoreService (lower is better)', () {
    late HighscoreService service;

    setUp(() {
      service = HighscoreService(
          FakeStorage(), const HighscoreConfig(higherIsBetter: false, label: 'D'));
    });

    test('fewer darts ranks higher', () {
      service.recordResult(value: 40, when: DateTime(2026, 1, 1));
      final rank = service.recordResult(value: 30, when: DateTime(2026, 1, 2));
      expect(rank, 1);
      expect(service.getHighscores().first.value, 30);
    });

    test('a higher (worse) value is rejected once list is full', () {
      for (int i = 20; i < 30; i++) {
        service.recordResult(value: i.toDouble(), when: DateTime(2026, 1, 1));
      }
      // Worst present is 29. A value of 40 (worse) must be rejected.
      final rank = service.recordResult(value: 40, when: DateTime(2026, 2, 1));
      expect(rank, isNull);
    });
  });

  group('HighscoreService.clear', () {
    test('empties the list', () {
      final s = HighscoreService(
          FakeStorage(), const HighscoreConfig(higherIsBetter: true, label: 'P'));
      s.recordResult(value: 10, when: DateTime(2026, 1, 1));
      s.clear();
      expect(s.getHighscores(), isEmpty);
    });
  });
}
