import 'package:flutter/material.dart';
import 'package:dart/widget/summary_dialog.dart';

/// Service for handling common summary dialog operations
class SummaryService {
  /// Show a standardized game summary dialog
  static void showGameSummary(
    BuildContext context, {
    required List<SummaryLine> summaryLines,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return SummaryDialog(lines: summaryLines);
      },
    );
  }

  /// Create a standard summary line for game completion status
  static SummaryLine createCompletionLine(String gameName, bool completed) {
    String checkSymbol = completed ? "✅" : "❌";
    return SummaryLine('$gameName geschafft', '', checkSymbol: checkSymbol);
  }

  /// Create a standard summary line for numeric values
  static SummaryLine createValueLine(String label, dynamic value,
      {bool emphasized = false}) {
    return SummaryLine(label, value.toString(), emphasized: emphasized);
  }

  /// Create a standard summary line for averages/calculated values
  static SummaryLine createAverageLine(String label, double value,
      {int decimals = 1, bool emphasized = true}) {
    return SummaryLine(label, value.toStringAsFixed(decimals),
        emphasized: emphasized);
  }

  /// Create a summary line announcing a new Top-10 highscore at [rank], or
  /// return null when [rank] is null (no new highscore). Shown emphasized with
  /// a trophy so it stands out in the summary dialog.
  static SummaryLine? createHighscoreLine(int? rank) {
    if (rank == null) return null;
    return SummaryLine('Neuer Highscore! Platz $rank', '',
        emphasized: true, checkSymbol: '🏆');
  }

  /// Build the end-of-game recap lines comparing this session's [value] to the
  /// personal [best] and the [recentAvg] of recent sessions (C3). Any of
  /// [best]/[recentAvg] may be null (shown only when available). [decimal]
  /// controls integer vs. one-decimal formatting to match the game's metric.
  static List<SummaryLine> createRecapLines({
    required double value,
    double? best,
    double? recentAvg,
    bool decimal = false,
  }) {
    String fmt(double v) => decimal ? v.toStringAsFixed(1) : v.round().toString();
    final lines = <SummaryLine>[
      SummaryLine('Diese Session', fmt(value)),
    ];
    if (best != null) lines.add(SummaryLine('Bestwert', fmt(best)));
    if (recentAvg != null) {
      lines.add(SummaryLine('Ø letzte', fmt(recentAvg)));
    }
    return lines;
  }

  /// Create summary lines for common game statistics
  static List<SummaryLine> createStandardSummaryLines({
    required String gameName,
    required bool gameCompleted,
    required Map<String, dynamic> gameStats,
    String? averageLabel,
    double? averageValue,
  }) {
    List<SummaryLine> lines = [];

    // Add completion status
    lines.add(createCompletionLine(gameName, gameCompleted));

    // Add game-specific stats
    gameStats.forEach((label, value) {
      if (value is double) {
        lines.add(createAverageLine(label, value, emphasized: false));
      } else {
        lines.add(createValueLine(label, value));
      }
    });

    // Add average if provided
    if (averageLabel != null && averageValue != null) {
      lines.add(createAverageLine(averageLabel, averageValue));
    }

    return lines;
  }
}
