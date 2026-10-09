import 'dart:convert';

import 'package:dart/services/storage_service.dart';

/// Storage key under which a game's dated result history is persisted inside
/// that game's own [StorageService] container (alongside stats/highscores).
const String resultHistoryKey = 'result_history';

/// Maximum number of result-history entries kept per game (bounded for
/// storage/quota safety; mirrors the throw-log bounding rationale).
const int maxResultHistoryEntries = 200;

/// A single dated game result: the primary metric [value] on day [date].
class ResultEntry {
  /// Day the game was played (date-only resolution).
  final DateTime date;

  /// The game's primary result metric for that session (same value the game
  /// records as its highscore primary value).
  final double value;

  const ResultEntry({required this.date, required this.value});

  Map<String, dynamic> toJson() => {
        'd': _dateOnly(date).toIso8601String(),
        'v': value,
      };

  factory ResultEntry.fromJson(Map<String, dynamic> json) => ResultEntry(
        date: DateTime.tryParse(json['d'] as String? ?? '') ?? DateTime(1970),
        value: (json['v'] as num?)?.toDouble() ?? 0,
      );

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Records and reads a game's dated result history, persisted in that game's
/// own storage container under [resultHistoryKey].
///
/// Appended once per completed game (piggybacking on the existing highscore
/// recording), it powers the per-game trend view (B2) and — across games — the
/// training streak (B3). Games without a result (e.g. the Quiz) simply never
/// append.
class ResultHistoryService {
  final StorageService _storage;

  ResultHistoryService(this._storage);

  /// Read the stored history, oldest first.
  List<ResultEntry> getHistory() {
    final raw = _storage.read<String>(resultHistoryKey);
    return decode(raw);
  }

  /// Decode a raw stored history value (JSON array string) into entries,
  /// oldest first. Returns an empty list for anything unparseable.
  static List<ResultEntry> decode(dynamic raw) {
    if (raw is! String || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => ResultEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Append a result for [when] (defaults to now), trimming to the newest
  /// [maxResultHistoryEntries].
  void record(double value, {DateTime? when}) {
    final entries = getHistory();
    entries.add(ResultEntry(date: when ?? DateTime.now(), value: value));
    if (entries.length > maxResultHistoryEntries) {
      entries.removeRange(0, entries.length - maxResultHistoryEntries);
    }
    _storage.write(
      resultHistoryKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Distinct dates (date-only) on which this game was played.
  Set<DateTime> playedDates() =>
      getHistory().map((e) => ResultEntry._dateOnly(e.date)).toSet();
}
