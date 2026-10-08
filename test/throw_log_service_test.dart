import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:dart/services/throw_log_model.dart';
import 'package:dart/services/throw_log_service.dart';

/// A minimal in-memory fake of the single key/value we use, so we can test
/// real persistence round-trips and simulate a localStorage quota overflow.
///
/// It extends [GetStorage] only to satisfy the type; all storage goes through
/// the overridden [read]/[write]. [failWritesUntilAtMost] simulates the web
/// quota: a write throws unless the stored JSON array has at most that many
/// sessions, forcing the service to evict oldest and retry.
class _FakeStorage implements GetStorage {
  final Map<String, dynamic> _data = {};

  /// When set, writes whose 'sessions' array exceeds this many entries throw a
  /// quota error (simulating localStorage being full).
  int? maxSessions;

  @override
  T? read<T>(String key) => _data[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async {
    // get_storage's web backend surfaces quota errors via the returned Future;
    // the service awaits the write, so throwing here (async) exercises that.
    _writeSync(key, value);
  }

  void _writeSync(String key, dynamic value) {
    if (maxSessions != null && key == throwLogSessionsKey && value is String) {
      final decoded = jsonDecode(value);
      if (decoded is List && decoded.length > maxSessions!) {
        throw Exception('QuotaExceededError: the quota has been exceeded');
      }
    }
    _data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // The service only uses read/write; everything else is unused in tests.
    return null;
  }
}

ThrowSession _session(String gameId, {int darts = 2, bool scolia = true}) {
  return ThrowSession(
    gameId: gameId,
    date: DateTime(2026, 1, 1),
    fromScolia: scolia,
    darts: List.generate(
      darts,
      (i) => LoggedDart(
        segment: 20,
        ring: 'triple',
        value: 60,
        x: scolia ? 1.0 * i : null,
        y: scolia ? -1.0 * i : null,
        angle: scolia ? 90.0 : null,
      ),
    ),
  );
}

void main() {
  group('ThrowLogService', () {
    test('loads empty when storage has nothing', () {
      final svc = ThrowLogService(storage: _FakeStorage());
      svc.load();
      expect(svc.sessionCount, 0);
      expect(svc.allSessions, isEmpty);
    });

    test('logSession appends in memory and persists (round-trip)', () async {
      final storage = _FakeStorage();
      final svc = ThrowLogService(storage: storage);
      svc.load();

      await svc.logSession(_session('CR', darts: 3));
      expect(svc.sessionCount, 1);

      // A fresh service over the SAME storage sees the persisted session.
      final svc2 = ThrowLogService(storage: storage)..load();
      expect(svc2.sessionCount, 1);
      expect(svc2.allSessions.first.gameId, 'CR');
      expect(svc2.allSessions.first.darts.length, 3);
      // Spatial fields survive the round-trip.
      expect(svc2.allSessions.first.darts.first.hasCoordinates, isTrue);
    });

    test('empty sessions are ignored', () async {
      final svc = ThrowLogService(storage: _FakeStorage())..load();
      await svc.logSession(_session('CR', darts: 0));
      expect(svc.sessionCount, 0);
    });

    test('queries: dartsForGame and coordinatesForGame', () async {
      final svc = ThrowLogService(storage: _FakeStorage())..load();
      await svc.logSession(_session('CR', darts: 2, scolia: true)); // 2 coords
      await svc.logSession(_session('CR', darts: 1, scolia: false)); // 1 none
      await svc.logSession(_session('HI', darts: 3, scolia: true));

      expect(svc.sessionsForGame('CR').length, 2);
      expect(svc.dartsForGame('CR').length, 3); // 2 + 1
      expect(svc.coordinatesForGame('CR').length, 2); // only the scolia darts
      expect(svc.dartsForGame('HI').length, 3);
      expect(svc.dartsForGame('UNKNOWN'), isEmpty);
    });

    test('quota overflow evicts oldest sessions (FIFO) and retries', () async {
      final storage = _FakeStorage()..maxSessions = 2; // storage holds max 2
      final svc = ThrowLogService(storage: storage)..load();

      await svc.logSession(_session('A'));
      await svc.logSession(_session('B'));
      // Third write would exceed quota -> oldest ('A') evicted, retry succeeds.
      await svc.logSession(_session('C'));

      final ids = svc.allSessions.map((s) => s.gameId).toList();
      expect(ids, ['B', 'C']); // 'A' dropped, newest kept
      expect(svc.sessionCount, 2);

      // Persisted state matches memory.
      final reloaded = ThrowLogService(storage: storage)..load();
      expect(reloaded.allSessions.map((s) => s.gameId).toList(), ['B', 'C']);
    });

    test('clear wipes memory and storage', () async {
      final storage = _FakeStorage();
      final svc = ThrowLogService(storage: storage)..load();
      await svc.logSession(_session('CR'));
      expect(svc.sessionCount, 1);

      svc.clear();
      expect(svc.sessionCount, 0);
      final reloaded = ThrowLogService(storage: storage)..load();
      expect(reloaded.sessionCount, 0);
    });
  });
}
