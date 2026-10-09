import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dart/services/active_routine.dart';
import 'package:dart/services/routine_generator.dart';
import 'package:dart/widget/menu.dart';

/// Menu bar for routines (C1): when a routine is active, shows a "next up"
/// prompt to launch the next game; otherwise a button to start a new random
/// routine (one game from each category).
///
/// Launching reuses the normal game navigation, so each game runs its usual
/// flow — the routine only remembers the position and offers the next game.
class RoutineBar extends StatelessWidget {
  const RoutineBar({super.key, this.generator});

  /// Injectable for tests (seeded RNG); defaults to a real random generator.
  final RoutineGenerator? generator;

  /// Fixed bar height so switching between the idle button and the active
  /// banner (with buttons) never changes the menu layout.
  static const double _barHeight = 40;

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ActiveRoutine>();

    return SizedBox(
      height: _barHeight,
      child: Center(
        child: active.isActive ? _activeBanner(context, active) : _startButton(context, active),
      ),
    );
  }

  Widget _activeBanner(BuildContext context, ActiveRoutine active) {
    final nextId = active.nextGameId!;
    final item = Menu.gameItemById(nextId);
    final name = item?.name.replaceAll('\n', ' ') ?? nextId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(40, 215, 198, 132),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(120, 215, 198, 132)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Routine ${active.position}/${active.total} – weiter: $name',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color.fromARGB(255, 215, 198, 132), fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: const Color.fromARGB(255, 215, 198, 132),
            ),
            onPressed: item == null
                ? null
                : () {
                    active.advance();
                    Menu.launchGame(context, item);
                  },
            child: const Text('Start'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: Colors.white54,
            ),
            onPressed: () => active.cancel(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Widget _startButton(BuildContext context, ActiveRoutine active) {
    return TextButton.icon(
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: const Icon(Icons.playlist_play,
          color: Color.fromARGB(255, 215, 198, 132)),
      label: const Text('Routine starten',
          style: TextStyle(color: Color.fromARGB(255, 215, 198, 132))),
      onPressed: () {
        final routine = (generator ?? RoutineGenerator()).generate();
        active.start(routine);
        final first = Menu.gameItemById(routine.gameIds.first);
        if (first != null) {
          active.advance();
          Menu.launchGame(context, first);
        }
      },
    );
  }
}
