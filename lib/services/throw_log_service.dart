import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dart/services/throw_log_model.dart';
import 'package:get_storage/get_storage.dart';

/// Storage container id for the throw log (separate from per-game containers).
const String throwLogContainer = 'throw_log';

/// Key under which the session list JSON array is stored.
const String throwLogSessionsKey = 'sessions';

/// In-memory analytics layer for the per-dart throw log, backed by
/// `get_storage`.
///
/// Design (see doc/training-enhancements-plan.md, step A0):
/// - **Startup:** [load] reads all persisted [ThrowSession]s into memory once.
/// - **Runtime:** queries (for the A2 heatmap / A3 metrics) run against the
///   in-memory list — pure Dart, no per-query storage access.
/// - **Session end:** [logSession] appends one session in memory and persists
///   the whole list once (never per dart).
/// - **Platform-adaptive eviction:** persistence goes through a quota-aware
///   write. On web, a `localStorage` quota overflow drops the oldest session(s)
///   (FIFO) and retries until it fits. On Android (file-backed) this never
///   triggers, so the full history is kept.
class ThrowLogService {
  ThrowLogService({GetStorage? storage}) : _injectedStorage = storage;

  final GetStorage? _injectedStorage;

  /// All sessions held in memory, oldest first. Exposed read-only.
  final List<ThrowSession> _sessions = <ThrowSession>[];

  bool _loaded = false;

  GetStorage? get _storage {
    try {
      return _injectedStorage ?? GetStorage(throwLogContainer);
    } catch (e) {
      developer.log('Throw log storage unavailable',
          error: e, name: 'ThrowLogService');
      return null;
    }
  }

  /// Load all persisted sessions into memory. Idempotent; safe to call once at
  /// startup. Never throws — a corrupt/absent log yields an empty list.
  void load() {
    _sessions.clear();
    final raw = _storage?.read(throwLogSessionsKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _sessions.addAll(decoded
              .whereType<Map>()
              .map((e) => ThrowSession.fromJson(Map<String, dynamic>.from(e))));
        }
      } catch (e) {
        developer.log('Failed to parse throw log; starting empty',
            error: e, name: 'ThrowLogService');
      }
    }
    _loaded = true;
  }

  /// All logged sessions, oldest first (read-only view).
  List<ThrowSession> get allSessions {
    if (!_loaded) load();
    return List.unmodifiable(_sessions);
  }

  /// Number of sessions currently held.
  int get sessionCount => allSessions.length;

  /// All sessions for a given game id, oldest first.
  List<ThrowSession> sessionsForGame(String gameId) =>
      allSessions.where((s) => s.gameId == gameId).toList();

  /// All darts for a given game id across every session (flattened), oldest
  /// first. The basis for the A2 heatmap and A3 metrics.
  List<LoggedDart> dartsForGame(String gameId) =>
      sessionsForGame(gameId).expand((s) => s.darts).toList();

  /// All darts for a game that carry board landing coordinates (Scolia only).
  List<LoggedDart> coordinatesForGame(String gameId) =>
      dartsForGame(gameId).where((d) => d.hasCoordinates).toList();

  /// Append a completed [session] to the in-memory list and persist. Returns
  /// true if persistence succeeded (false only when storage is unavailable).
  ///
  /// An empty session (no darts) is ignored.
  /// Append a completed [session] and persist. Returns a future completing with
  /// true on successful persistence (false only when storage is unavailable or
  /// a single oversized session can't be stored). The in-memory append is
  /// immediate, so queries see the new session even before the write resolves.
  ///
  /// An empty session (no darts) is ignored.
  Future<bool> logSession(ThrowSession session) async {
    if (!_loaded) load();
    if (session.darts.isEmpty) return true;
    _sessions.add(session);
    return _persist();
  }

  /// Remove all sessions (clears memory and storage).
  void clear() {
    if (!_loaded) load();
    _sessions.clear();
    _storage?.write(throwLogSessionsKey, jsonEncode(const <dynamic>[]));
  }

  /// Persist the full in-memory list with platform-adaptive, quota-aware
  /// eviction. On a storage quota overflow (web `localStorage`), drops the
  /// oldest session and retries until the write succeeds or the log is empty.
  ///
  /// Awaits the write so a quota error is caught whether the storage backend
  /// throws it synchronously or surfaces it as a rejected Future (get_storage's
  /// web backend does the latter).
  Future<bool> _persist() async {
    final storage = _storage;
    if (storage == null) return false;

    while (true) {
      final json = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      try {
        await storage.write(throwLogSessionsKey, json);
        return true;
      } catch (e) {
        // Likely a localStorage QuotaExceededError on web. Drop the oldest
        // session (FIFO) and retry. Pruning is logged, never silent.
        if (_isQuotaError(e) && _sessions.length > 1) {
          final dropped = _sessions.removeAt(0);
          developer.log(
            'Throw log full; evicted oldest session '
            '(${dropped.gameId}, ${dropped.date.toIso8601String()}). '
            '${_sessions.length} sessions remain.',
            name: 'ThrowLogService',
          );
          continue;
        }
        if (_isQuotaError(e) && _sessions.length == 1) {
          // A single session that alone exceeds quota: give up on persisting
          // it rather than loop forever, but keep it in memory for this run.
          developer.log(
            'Throw log: single session exceeds storage quota; not persisted.',
            error: e,
            name: 'ThrowLogService',
          );
          return false;
        }
        developer.log('Failed to persist throw log',
            error: e, name: 'ThrowLogService');
        return false;
      }
    }
  }

  /// Heuristic detection of a storage quota-exceeded error (web localStorage).
  /// `get_storage`'s web backend surfaces the browser's DOMException whose name
  /// / message mentions "quota"; we match defensively on the string form.
  static bool _isQuotaError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('quota') || s.contains('exceeded');
  }
}
