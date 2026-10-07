import 'dart:convert';

import 'package:dart/services/storage_service.dart';

/// Storage key under which a game's Top-10 highscore list is persisted inside
/// that game's own [StorageService] container.
const String highscoreStorageKey = 'highscores';

/// Maximum number of entries kept per game.
const int maxHighscoreEntries = 10;

/// A single dated highscore entry for one game.
///
/// [value] is the primary ranking metric for the game, [value2] an optional
/// tie-breaker (shown alongside but only used to order equal [value]s). [date]
/// is the day the game was played, stored as `dd.MM.yyyy` (German format).
class HighscoreEntry {
  final double value;
  final double? value2;
  final String date;

  const HighscoreEntry({
    required this.value,
    required this.date,
    this.value2,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        if (value2 != null) 'value2': value2,
        'date': date,
      };

  factory HighscoreEntry.fromJson(Map<String, dynamic> json) => HighscoreEntry(
        value: (json['value'] as num).toDouble(),
        value2: json['value2'] == null
            ? null
            : (json['value2'] as num).toDouble(),
        date: json['date'] as String,
      );

  /// Format today's date as `dd.MM.yyyy`.
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

/// Ranking configuration for a single game: whether higher values are better
/// for the primary metric and (optionally) the tie-breaker, plus display
/// metadata used by the highscore dialog and the stats page.
class HighscoreConfig {
  /// Whether a higher primary [value] is better.
  final bool higherIsBetter;

  /// Whether a higher tie-breaker [value2] is better. Ignored when entries
  /// carry no tie-breaker.
  final bool higherIsBetter2;

  /// Short label for the primary value column (e.g. 'Darts', 'Punkte').
  final String label;

  /// Short label for the tie-breaker column, or null when there is none.
  final String? label2;

  /// When true, the primary value is formatted with one decimal; otherwise as
  /// an integer.
  final bool decimal;

  /// When true, the tie-breaker value is formatted with one decimal.
  final bool decimal2;

  /// When true, values are medal emojis rather than numbers (Sportabzeichen).
  final bool isMedal;

  const HighscoreConfig({
    required this.higherIsBetter,
    required this.label,
    this.higherIsBetter2 = true,
    this.label2,
    this.decimal = false,
    this.decimal2 = false,
    this.isMedal = false,
  });

  /// Format the primary [value] for display (integer, one decimal, or medal).
  String formatValue(double value) {
    if (isMedal) return _medalEmoji(value);
    return decimal ? value.toStringAsFixed(1) : value.round().toString();
  }

  /// Format the tie-breaker [value2] for display, or empty when absent.
  String formatValue2(double? value) {
    if (value == null) return '';
    return decimal2 ? value.toStringAsFixed(1) : value.round().toString();
  }

  static const List<String> _medals = ['🥉', '🥉+', '🥈', '🥈+', '🥇', '🥇+'];

  static String _medalEmoji(double value) {
    final i = value.round();
    return (i >= 0 && i < _medals.length) ? _medals[i] : '😢';
  }
}

/// Per-game highscore ranking configuration, keyed by the game's storage
/// container id (the MenuItem id, or RTCD/RTCT for the RTC mode split).
///
/// Only games that keep a Top-10 highscore list appear here. The Quiz
/// (FinishQuest) has no highscore and is intentionally absent.
const Map<String, HighscoreConfig> highscoreConfigs = {
  // Checkout games: rank by number of finishes (higher better),
  // tie-break by average score (higher better).
  '170m3': HighscoreConfig(
      higherIsBetter: true, label: 'Checks', label2: 'ØPunkte', decimal2: true),
  '501m7': HighscoreConfig(
      higherIsBetter: true, label: 'Checks', label2: 'ØPunkte', decimal2: true),
  '501x5': HighscoreConfig(
      higherIsBetter: true, label: 'Checks', label2: 'ØPunkte', decimal2: true),
  // Cricket: rank by darts used (lower better), tie-break avg hits (higher).
  'CR': HighscoreConfig(
      higherIsBetter: false, label: 'Darts', label2: 'ØTreffer', decimal2: true),
  // Round the Clock: rank by darts (lower better); only finished games enter.
  'RTCS': HighscoreConfig(higherIsBetter: false, label: 'Darts'),
  'RTCD': HighscoreConfig(higherIsBetter: false, label: 'Darts'),
  'RTCT': HighscoreConfig(higherIsBetter: false, label: 'Darts'),
  // Plan Hit: points (higher), tie-break average (higher).
  'PLANHIT': HighscoreConfig(
      higherIsBetter: true, label: 'Punkte', label2: 'ØRunde', decimal2: true),
  // Half it: score (higher).
  'HI': HighscoreConfig(higherIsBetter: true, label: 'Punkte'),
  // Catch 40: points (higher), tie-break hits (higher).
  'C40': HighscoreConfig(
      higherIsBetter: true, label: 'Punkte', label2: 'Checks'),
  // Check 121: highest target (higher), tie-break highest save point (higher).
  'C121': HighscoreConfig(
      higherIsBetter: true, label: 'Höchstes Ziel', label2: 'Safepoint'),
  // Double Path: round points (higher), tie-break round average (higher).
  'DPath': HighscoreConfig(
      higherIsBetter: true,
      label: 'Punkte/Runde',
      label2: 'ØRunde',
      decimal2: true),
  // 10 Up 1 Down: successes (higher), tie-break highest target (higher).
  '10U1D': HighscoreConfig(
      higherIsBetter: true, label: 'Checks', label2: 'Höchstes Ziel'),
  // Shoot X: numbers hit (higher).
  '99x20': HighscoreConfig(higherIsBetter: true, label: 'Treffer'),
  // Big Ts: round points (higher), tie-break round average (higher).
  'BT': HighscoreConfig(
      higherIsBetter: true,
      label: 'Punkte/Runde',
      label2: 'ØRunde',
      decimal2: true),
  // 2 Darts: successes (higher).
  '2D': HighscoreConfig(higherIsBetter: true, label: 'Checks'),
  // Bob's 27: total points (higher), tie-break successful rounds (higher).
  'B27': HighscoreConfig(
      higherIsBetter: true, label: 'Punkte', label2: 'Erf. Runden'),
  // Kill Bull: score (higher), tie-break rounds (higher).
  'KB': HighscoreConfig(
      higherIsBetter: true, label: 'Punkte', label2: 'Runden'),
  // Speed Bull: bull hits in 1 minute (higher).
  'SB': HighscoreConfig(higherIsBetter: true, label: 'Treffer'),
  // Across Board: darts (lower better); only finished games enter.
  'ACROSSBOARD': HighscoreConfig(higherIsBetter: false, label: 'Darts'),
  // Credit Finish: average checks % (higher).
  'CREDITFINISH':
      HighscoreConfig(higherIsBetter: true, label: 'ØChecks %', decimal: true),
  // Bayrisches Sportabzeichen: awarded medal rank (higher). Failed runs
  // (no medal) do not enter the list.
  'CHALLENGE':
      HighscoreConfig(higherIsBetter: true, label: 'Medaille', isMedal: true),
};

/// Manages a single game's Top-10 highscore list, persisted in that game's
/// own storage container under [highscoreStorageKey].
///
/// Insertion rule (see feature spec): a candidate enters the list when there
/// are fewer than [maxHighscoreEntries] entries, or when it is strictly better
/// than the current worst (rank-10) entry. Equal values are allowed as new
/// dated entries but never displace an equally-good existing entry — they sort
/// after it. "To climb you must be strictly better."
class HighscoreService {
  final StorageService _storage;
  final HighscoreConfig _config;

  HighscoreService(this._storage, this._config);

  /// Read the current ordered list (best first), clamped to 10 entries.
  List<HighscoreEntry> getHighscores() {
    final raw = _storage.read<String>(highscoreStorageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final entries = decoded
          .whereType<Map>()
          .map((e) => HighscoreEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _sort(entries);
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// Try to record a new result. Returns the 1-based rank the new entry took,
  /// or `null` if it did not qualify for the Top-10.
  int? recordResult({
    required double value,
    double? value2,
    DateTime? when,
  }) {
    final entries = getHighscores();
    final candidate = HighscoreEntry(
      value: value,
      value2: value2,
      date: HighscoreEntry.formatDate(when ?? DateTime.now()),
    );

    // If the list is full, the candidate must be strictly better than the
    // current worst entry to enter at all.
    if (entries.length >= maxHighscoreEntries) {
      final worst = entries.last;
      if (!_isStrictlyBetter(candidate, worst)) {
        return null;
      }
    }

    entries.add(candidate);
    _sort(entries);

    // Trim to the max, keeping the best entries.
    if (entries.length > maxHighscoreEntries) {
      entries.removeRange(maxHighscoreEntries, entries.length);
    }

    _write(entries);

    // Determine the rank of the candidate (identity by reference).
    final index = entries.indexOf(candidate);
    return index >= 0 ? index + 1 : null;
  }

  /// Clear the highscore list for this game.
  void clear() {
    _storage.write(highscoreStorageKey, jsonEncode(<Map<String, dynamic>>[]));
  }

  void _write(List<HighscoreEntry> entries) {
    _storage.write(
      highscoreStorageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Order entries best-first by primary metric, then tie-breaker. Equal
  /// entries keep their original order (a stable sort via index decoration), so
  /// an equal result recorded later stays below an equal earlier one — "you
  /// tied the record but didn't beat it".
  void _sort(List<HighscoreEntry> entries) {
    final decorated = entries
        .asMap()
        .entries
        .map((e) => MapEntry(e.key, e.value))
        .toList();
    decorated.sort((a, b) {
      final primary = _config.higherIsBetter
          ? b.value.value.compareTo(a.value.value)
          : a.value.value.compareTo(b.value.value);
      if (primary != 0) return primary;

      if (a.value.value2 != null && b.value.value2 != null) {
        final secondary = _config.higherIsBetter2
            ? b.value.value2!.compareTo(a.value.value2!)
            : a.value.value2!.compareTo(b.value.value2!);
        if (secondary != 0) return secondary;
      }
      // Equal on all metrics: preserve original order via the decoration index.
      return a.key.compareTo(b.key);
    });
    for (int i = 0; i < decorated.length; i++) {
      entries[i] = decorated[i].value;
    }
  }

  /// A candidate is strictly better than [other] if its primary metric wins, or
  /// (when primaries tie and both carry a tie-breaker) its tie-breaker wins.
  bool _isStrictlyBetter(HighscoreEntry candidate, HighscoreEntry other) {
    final primaryCmp = _config.higherIsBetter
        ? candidate.value.compareTo(other.value)
        : other.value.compareTo(candidate.value);
    if (primaryCmp != 0) return primaryCmp > 0;

    if (candidate.value2 != null && other.value2 != null) {
      final secondaryCmp = _config.higherIsBetter2
          ? candidate.value2!.compareTo(other.value2!)
          : other.value2!.compareTo(candidate.value2!);
      return secondaryCmp > 0;
    }
    return false;
  }
}
