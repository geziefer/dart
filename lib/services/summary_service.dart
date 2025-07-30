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
  static SummaryLine createValueLine(String label, dynamic value, {bool emphasized = false}) {
    return SummaryLine(label, value.toString(), emphasized: emphasized);
  }
  
  /// Create a standard summary line for averages/calculated values
  static SummaryLine createAverageLine(String label, double value, {int decimals = 1, bool emphasized = true}) {
    return SummaryLine(label, value.toStringAsFixed(decimals), emphasized: emphasized);
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
