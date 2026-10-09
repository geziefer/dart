import 'package:dart/services/result_history_service.dart';
import 'package:dart/services/storage_service.dart';

/// A snapshot of training-activity streak metrics.
class StreakInfo {
  /// Consecutive-day streak ending today (or yesterday if not yet trained
  /// today). 0 when the most recent training was longer ago.
  final int currentStreak;

  /// Whether a game was played today.
  final bool trainedToday;

  /// Distinct days trained within the current ISO week (Mon–Sun).
  final int daysThisWeek;

  const StreakInfo({
    required this.currentStreak,
    required this.trainedToday,
    required this.daysThisWeek,
  });

  static const empty =
      StreakInfo(currentStreak: 0, trainedToday: false, daysThisWeek: 0);
}

/// Computes training streaks from the per-game result histories (B3).
///
/// Streaks are derived from the union of all games' played-dates, so any game
/// that records a result counts toward the daily streak.
class StreakService {
  /// Game storage container ids whose histories contribute to the streak.
  final List<String> gameIds;

  /// Factory for the per-game result-history service (injectable for tests).
  final ResultHistoryService Function(String gameId) _historyFor;

  StreakService(
    this.gameIds, {
    ResultHistoryService Function(String gameId)? historyFor,
  }) : _historyFor =
            historyFor ?? ((id) => ResultHistoryService(StorageService(id)));

  /// Collect the union of distinct played-dates across all games.
  Set<DateTime> _allPlayedDates() {
    final dates = <DateTime>{};
    for (final id in gameIds) {
      dates.addAll(_historyFor(id).playedDates());
    }
    return dates;
  }

  /// Compute streak info relative to [today] (defaults to the current date).
  StreakInfo compute({DateTime? today}) {
    final ref = _dateOnly(today ?? DateTime.now());
    final played = _allPlayedDates();
    if (played.isEmpty) return StreakInfo.empty;

    final trainedToday = played.contains(ref);

    // Current streak: count back from today (or yesterday if today is empty)
    // over consecutive played days.
    int streak = 0;
    DateTime cursor = trainedToday ? ref : ref.subtract(const Duration(days: 1));
    // If neither today nor yesterday was played, the streak is 0.
    if (played.contains(cursor)) {
      while (played.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    // Days trained this ISO week (Monday 00:00 .. today).
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    final daysThisWeek = played.where((d) {
      return !d.isBefore(monday) && !d.isAfter(ref);
    }).length;

    return StreakInfo(
      currentStreak: streak,
      trainedToday: trainedToday,
      daysThisWeek: daysThisWeek,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
