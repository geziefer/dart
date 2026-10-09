import 'package:flutter/material.dart';
import 'package:dart/services/stats_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/services/highscore_service.dart';
import 'package:dart/services/result_history_service.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:dart/utils/stats_formatter.dart';

abstract class ControllerBase extends ChangeNotifier {
  // Common services that all controllers can use
  StatsService? _statsService;
  HighscoreService? _highscoreService;
  ResultHistoryService? _resultHistoryService;

  /// The game id this controller was initialized with (storage container id),
  /// or null before initialization. Used to open the highscore dialog.
  String? _gameId;

  /// The game id for the highscore dialog, or null when this game has no
  /// highscore list configured.
  String? get highscoreGameId =>
      (_gameId != null && highscoreConfigs.containsKey(_gameId))
          ? _gameId
          : null;

  /// 1-based rank of a highscore achieved in the just-finished game, or null
  /// if no new highscore was recorded. Reset at the start of each game and set
  /// by [recordHighscore]. Used to show a line in the summary dialog.
  int? lastHighscoreRank;

  /// End-of-game recap lines (this session vs. best / recent average), computed
  /// by [recordHighscore]. Appended to the summary dialog (C3). Empty when the
  /// game records no highscore/result.
  List<SummaryLine> lastSessionRecap = const [];

  /// Whether the player has made any progress in the current game (thrown a
  /// dart / entered input), used to decide whether leaving the game needs a
  /// confirmation. Defaults to false (fresh game, safe to leave without
  /// asking); each concrete controller overrides it with a cheap check of its
  /// own state (e.g. darts thrown > 0 or a non-initial round).
  bool get hasGameProgress => false;

  // Callback functions for UI interactions (to decouple from BuildContext)
  VoidCallback? onGameEnded;
  Function(String message)? onShowMessage;
  Function(int remaining, int score)?
      onShowCheckout; // For games with checkout dialogs
  VoidCallback? onCheckoutClosed; // Called when checkout dialog is closed

  /// Initialize common services (should be called by concrete controllers).
  ///
  /// When [gameId] is provided and a [HighscoreConfig] exists for it, a
  /// [HighscoreService] is created so the controller can record Top-10
  /// highscores. Games without a highscore (e.g. the Quiz) omit [gameId].
  void initializeServices(StorageService storageService, {String? gameId}) {
    _statsService = StatsService(storageService);
    _gameId = gameId;
    lastHighscoreRank = null;
    lastSessionRecap = const [];
    final config = gameId == null ? null : highscoreConfigs[gameId];
    _highscoreService =
        config == null ? null : HighscoreService(storageService, config);
    // Result history: dated per-game results powering the trend view (B2) and
    // training streak (B3). Only games that record a highscore contribute.
    _resultHistoryService =
        config == null ? null : ResultHistoryService(storageService);
  }

  /// Get the stats service (protected access for subclasses)
  StatsService get statsService {
    if (_statsService == null) {
      throw StateError(
          'StatsService not initialized. Call initializeServices() first.');
    }
    return _statsService!;
  }

  /// The highscore service for this game, or null if the game has no highscore
  /// list configured.
  HighscoreService? get highscoreService => _highscoreService;

  /// Record a single-game result into this game's Top-10 highscore list.
  ///
  /// [value] is the primary ranking metric, [value2] an optional tie-breaker.
  /// Sets [lastHighscoreRank] to the achieved 1-based rank (or null if the
  /// result did not qualify) so the summary can report it. No-op when the game
  /// has no highscore configured.
  void recordHighscore(double value, {double? value2}) {
    final service = _highscoreService;
    if (service == null) {
      lastHighscoreRank = null;
      return;
    }
    // Build the end-of-game recap BEFORE recording, so "best" and "recent
    // average" reflect prior sessions, not the one just played.
    _computeSessionRecap(value);
    lastHighscoreRank = service.recordResult(value: value, value2: value2);
    // Also append to the dated result history (trend view + streaks). This
    // records every completed game, not only new highscores.
    _resultHistoryService?.record(value);
  }

  /// Number of recent sessions averaged for the recap's "Ø letzte" line.
  static const int _recapRecentCount = 5;

  /// Populate [lastSessionRecap] comparing [value] to the prior best and the
  /// average of recent prior sessions. Uses the game's highscore config for
  /// formatting. No-op (empty) when there's no highscore config.
  void _computeSessionRecap(double value) {
    final config = _gameId == null ? null : highscoreConfigs[_gameId];
    if (config == null) {
      lastSessionRecap = const [];
      return;
    }
    // Prior best = current rank-1 highscore value (before this result).
    final entries = _highscoreService?.getHighscores() ?? const [];
    final double? best = entries.isNotEmpty ? entries.first.value : null;

    // Recent average over the last N prior results.
    final history = _resultHistoryService?.getHistory() ?? const [];
    double? recentAvg;
    if (history.isNotEmpty) {
      final recent = history.length <= _recapRecentCount
          ? history
          : history.sublist(history.length - _recapRecentCount);
      recentAvg =
          recent.map((e) => e.value).reduce((a, b) => a + b) / recent.length;
    }

    lastSessionRecap = SummaryService.createRecapLines(
      value: value,
      best: best,
      recentAvg: recentAvg,
      decimal: config.decimal,
    );
  }

  /// Common method to update game statistics
  void updateGameStats() {
    statsService.incrementGameCount();
    updateSpecificStats();
  }

  /// Common method to trigger game end (calls callback instead of showing dialog directly)
  void triggerGameEnd() {
    updateGameStats();
    onGameEnded?.call();
  }

  /// Common method to show summary dialog
  void showSummaryDialog(BuildContext context) {
    List<SummaryLine> summaryLines = createSummaryLines();
    SummaryService.showGameSummary(context, summaryLines: summaryLines);
  }

  /// Format stats string using consistent formatting
  String formatStatsString({
    required int numberGames,
    required Map<String, dynamic> records,
    required Map<String, dynamic> averages,
  }) {
    return StatsFormatter.formatGameStats(
      numberGames: numberGames,
      records: records,
      averages: averages,
    );
  }

  // Virtual methods that concrete controllers can override

  /// Update game-specific statistics (called after common stats update)
  /// Override this method in concrete controllers
  void updateSpecificStats() {
    // Default implementation does nothing
  }

  /// Create summary lines for the game summary dialog
  /// Override this method in concrete controllers
  List<SummaryLine> createSummaryLines() {
    // Default implementation returns empty list
    return [];
  }

  /// Get the game title for display purposes
  /// Override this method in concrete controllers
  String getGameTitle() {
    return 'Game';
  }

  // Existing utility method
  String createMultilineString(List list1, List list2, String prefix,
      String postfix, List optional, int limit, bool enumerate) {
    String result = "";
    String enhancedPrefix = "";
    String enhancedPostfix = "";
    String optionalStatus = "";
    String listText = "";
    // max limit entries
    int to = list1.length;
    int from = (to > limit) ? to - limit : 0;
    for (int i = from; i < list1.length; i++) {
      enhancedPrefix = enumerate
          ? '$prefix ${i + 1}: '
          : (prefix.isNotEmpty ? '$prefix: ' : '');
      enhancedPostfix = postfix.isNotEmpty ? ' $postfix' : '';
      if (optional.isNotEmpty) {
        optionalStatus = optional[i] ? " ✅" : " ❌";
      }
      listText = list2.isEmpty ? '${list1[i]}' : '${list1[i]}: ${list2[i]}';
      result += '$enhancedPrefix$listText$enhancedPostfix$optionalStatus\n';
    }
    // delete last line break if any
    if (result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
