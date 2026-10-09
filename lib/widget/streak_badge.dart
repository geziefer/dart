import 'package:flutter/material.dart';

import 'package:dart/services/streak_service.dart';

/// Compact training-streak badge for the start menu (B3).
///
/// Shows a flame with the current consecutive-day streak and the number of
/// days trained this week. The flame is lit (gold) once the player has trained
/// today, dimmed otherwise, as a gentle nudge.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.gameIds, this.info});

  /// Game storage ids contributing to the streak.
  final List<String> gameIds;

  /// Pre-computed info (tests inject this); otherwise computed from storage.
  final StreakInfo? info;

  @override
  Widget build(BuildContext context) {
    final streak = info ?? StreakService(gameIds).compute();

    const gold = Color.fromARGB(255, 215, 198, 132);
    final flameColor = streak.trainedToday ? gold : Colors.white38;

    // Nothing trained yet: keep it unobtrusive.
    if (streak.currentStreak == 0 && streak.daysThisWeek == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: flameColor, size: 26),
        const SizedBox(width: 4),
        Text(
          '${streak.currentStreak}',
          style: TextStyle(
              color: flameColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Text(
          '${streak.daysThisWeek}/7',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }
}
