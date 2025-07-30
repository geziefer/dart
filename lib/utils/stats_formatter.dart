/// Utility class for formatting game statistics consistently
class StatsFormatter {
  
  /// Standard stats symbols
  static const String gamesSymbol = '#S';      // Number of games
  static const String recordSymbol = '♛';      // Record/best values
  static const String averageSymbol = 'Ø';     // Average values
  
  /// Format a complete stats string with games, records, and averages
  static String formatGameStats({
    required int numberGames,
    required Map<String, dynamic> records,
    required Map<String, dynamic> averages,
  }) {
    List<String> parts = [];
    
    // Always start with number of games
    parts.add('$gamesSymbol: $numberGames');
    
    // Add record values
    records.forEach((key, value) {
      String formattedValue = _formatValue(value);
      parts.add('$recordSymbol$key: $formattedValue');
    });
    
    // Add average values
    averages.forEach((key, value) {
      String formattedValue = _formatValue(value);
      parts.add('$averageSymbol$key: $formattedValue');
    });
    
    return parts.join('  ');
  }
  
  /// Format individual stat components
  static String formatStat(String symbol, String label, dynamic value) {
    String formattedValue = _formatValue(value);
    return '$symbol$label: $formattedValue';
  }
  
  /// Format a record stat
  static String formatRecord(String label, dynamic value) {
    return formatStat(recordSymbol, label, value);
  }
  
  /// Format an average stat
  static String formatAverage(String label, dynamic value) {
    return formatStat(averageSymbol, label, value);
  }
  
  /// Format games count
  static String formatGamesCount(int count) {
    return '$gamesSymbol: $count';
  }
  
  /// Private helper to format values consistently
  static String _formatValue(dynamic value) {
    if (value is double) {
      // Format doubles to 1 decimal place, preserving .0 for consistency
      return value.toStringAsFixed(1);
    } else if (value is int) {
      return value.toString();
    } else {
      return value.toString();
    }
  }
  
  /// Create a stats map for common game metrics
  static Map<String, String> createStatsMap({
    required int games,
    Map<String, dynamic>? records,
    Map<String, dynamic>? averages,
  }) {
    Map<String, String> statsMap = {};
    
    statsMap['games'] = formatGamesCount(games);
    
    records?.forEach((key, value) {
      statsMap['record_$key'] = formatRecord(key, value);
    });
    
    averages?.forEach((key, value) {
      statsMap['average_$key'] = formatAverage(key, value);
    });
    
    return statsMap;
  }
}
