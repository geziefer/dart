// Standalone migration script: converts an old DART stats export (version
// 1.0, flat per-game `record*`/`longterm*` keys with no highscore list) into
// the new structure (version 2.0) that carries a per-game Top-10 highscore
// list. Each game that has a usable record value gets exactly ONE synthesized
// highscore entry, dated with the export date.
//
// Usage:
//   dart run tool/migrate_highscores.dart <export.json>
//
// The input file is overwritten in place with the migrated structure. After
// migration no backward compatibility is needed.
//
// This script is intentionally dependency-free (pure dart:io / dart:convert)
// so it can run outside the Flutter app. The per-game ranking rules below MUST
// stay in sync with lib/services/highscore_service.dart (highscoreConfigs) and
// each controller's updateSpecificStats().

import 'dart:convert';
import 'dart:io';

/// Describes how to synthesize a highscore entry for one game from its old
/// flat stats map: which stored key holds the primary ranking value and which
/// (optional) key holds the tie-breaker.
class MigrationRule {
  final String primaryKey;
  final String? tieBreakKey;
  const MigrationRule(this.primaryKey, [this.tieBreakKey]);
}

/// Per-game migration rules keyed by storage container id. Mirrors the primary
/// metric + tie-breaker chosen in the app. Games absent here (e.g. the Quiz
/// 'FQ') get no highscore list. 'CHALLENGE' kept no stats in v1.0, so it has
/// no record to synthesize from and is omitted.
const Map<String, MigrationRule> migrationRules = {
  '170m3': MigrationRule('recordFinishes', 'recordScore'),
  '501m7': MigrationRule('recordFinishes', 'recordScore'),
  '501x5': MigrationRule('recordFinishes', 'recordScore'),
  'CR': MigrationRule('recordDarts', 'recordAvgHits'),
  'RTCS': MigrationRule('recordDarts'),
  'RTCD': MigrationRule('recordDarts'),
  'RTCT': MigrationRule('recordDarts'),
  'PLANHIT': MigrationRule('recordPoints', 'recordAverage'),
  'HI': MigrationRule('recordScore'),
  'C40': MigrationRule('recordPoints', 'recordHits'),
  'C121': MigrationRule('highestTarget', 'highestSavePoint'),
  'DPath': MigrationRule('recordRoundPoints', 'recordRoundAverage'),
  '10U1D': MigrationRule('recordSuccesses', 'recordHighestTarget'),
  '99x20': MigrationRule('recordNumbers'),
  'BT': MigrationRule('recordRoundPoints', 'recordRoundAverage'),
  '2D': MigrationRule('recordSuccesses'),
  'B27': MigrationRule('recordTotal', 'recordSuccessful'),
  'KB': MigrationRule('recordScore', 'recordRounds'),
  'SB': MigrationRule('recordHits'),
  'ACROSSBOARD': MigrationRule('recordDarts'),
  'CREDITFINISH': MigrationRule('bestAvgChecks'),
};

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d.$m.${date.year}';
}

/// A record value counts as "present" when it is a number greater than zero.
/// Old code used 0 as the "no record yet" sentinel for all these keys.
double? _usableValue(dynamic raw) {
  if (raw is num && raw > 0) return raw.toDouble();
  return null;
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/migrate_highscores.dart <export.json>');
    exitCode = 64; // EX_USAGE
    return;
  }

  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('File not found: ${args.first}');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final Map<String, dynamic> data;
  try {
    data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Could not parse JSON: $e');
    exitCode = 65; // EX_DATAERR
    return;
  }

  final games = data['games'];
  if (games is! Map) {
    stderr.writeln("Invalid export: missing 'games' object.");
    exitCode = 65;
    return;
  }

  // Date for synthesized entries: the export date, else today.
  DateTime entryDate;
  final exportDate = data['exportDate'];
  entryDate = (exportDate is String)
      ? (DateTime.tryParse(exportDate) ?? DateTime.now())
      : DateTime.now();
  final dateStr = _formatDate(entryDate);

  int migratedGames = 0;
  games.forEach((gameId, gameData) {
    if (gameData is! Map) return;
    final stats = gameData['stats'];
    if (stats is! Map) return;

    final rule = migrationRules[gameId];
    if (rule == null) {
      // No highscore for this game: ensure any stray key is removed.
      stats.remove('highscores');
      return;
    }

    final primary = _usableValue(stats[rule.primaryKey]);
    if (primary == null) {
      // No usable record to seed from — leave an empty list.
      stats['highscores'] = <dynamic>[];
      return;
    }

    final entry = <String, dynamic>{'value': primary, 'date': dateStr};
    if (rule.tieBreakKey != null) {
      final v2 = _usableValue(stats[rule.tieBreakKey]);
      if (v2 != null) entry['value2'] = v2;
    }

    stats['highscores'] = <dynamic>[entry];
    migratedGames++;
  });

  data['version'] = '2.0';

  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  stdout.writeln(
      'Migrated $migratedGames game(s) to version 2.0 → ${file.path}');
}
