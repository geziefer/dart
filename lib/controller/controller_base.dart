import 'package:flutter/material.dart';
import 'package:dart/services/stats_service.dart';
import 'package:dart/services/summary_service.dart';
import 'package:dart/services/storage_service.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:dart/utils/stats_formatter.dart';

abstract class ControllerBase extends ChangeNotifier {
  // Common services that all controllers can use
  StatsService? _statsService;
  
  // Callback functions for UI interactions (to decouple from BuildContext)
  VoidCallback? onGameEnded;
  Function(String message)? onShowMessage;
  Function(int remaining)? onShowCheckout; // For games with checkout dialogs
  
  /// Initialize common services (should be called by concrete controllers)
  void initializeServices(StorageService storageService) {
    _statsService = StatsService(storageService);
  }
  
  /// Get the stats service (protected access for subclasses)
  StatsService get statsService {
    if (_statsService == null) {
      throw StateError('StatsService not initialized. Call initializeServices() first.');
    }
    return _statsService!;
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
