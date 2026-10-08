import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dart/widget/header.dart';
import 'package:dart/widget/highscore_dialog.dart';
import 'package:dart/services/highscore_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Layout shared by all game views. Keeps the screen on while a game is
/// active (wake lock enabled on init, released on dispose) so the display
/// doesn't blank during Scolia play when no touch input is happening.
class GameLayout extends StatefulWidget {
  const GameLayout({
    super.key,
    required this.title,
    required this.mainContent,
    required this.statsContent,
    this.highscoreGameId,
    this.highscoreGameName,
    this.hasProgress,
  });

  final String title;
  final Widget mainContent;
  final Widget statsContent;

  /// When set to a game id that has a highscore configuration, a trophy icon is
  /// shown in the bottom-right of the stats area opening the Top-10 dialog.
  final String? highscoreGameId;

  /// Display name for the highscore dialog title (defaults to [title]).
  final String? highscoreGameName;

  /// Predicate evaluated when the back arrow is tapped. When it returns true
  /// (the player has made progress), a confirmation dialog is shown before
  /// leaving the game. When null or false, the game is left immediately.
  final bool Function()? hasProgress;

  @override
  State<GameLayout> createState() => _GameLayoutState();
}

class _GameLayoutState extends State<GameLayout> {
  @override
  void initState() {
    super.initState();
    // wakelock_plus' web implementation (no_sleep.js) throws a non-fatal
    // TypeError; the real target is Android, so skip the wake lock on web.
    if (!kIsWeb) WakelockPlus.enable();
  }

  @override
  void dispose() {
    if (!kIsWeb) WakelockPlus.disable();
    super.dispose();
  }

  /// Whether to show the highscore trophy: only when a configured game id is
  /// provided (so the stats/settings page and the Quiz do not show it).
  bool get _showHighscoreIcon {
    final id = widget.highscoreGameId;
    return id != null && highscoreConfigs.containsKey(id);
  }

  void _openHighscores(BuildContext context) {
    final id = widget.highscoreGameId;
    if (id == null) return;
    showDialog(
      context: context,
      builder: (_) => HighscoreDialog(
        gameId: id,
        gameName: widget.highscoreGameName ?? widget.title,
      ),
    );
  }

  /// Handle the back arrow: if the game reports progress, confirm before
  /// leaving; otherwise leave immediately.
  Future<void> _onBack(BuildContext context) async {
    final hasProgress = widget.hasProgress?.call() ?? false;
    if (!hasProgress) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 17, 17, 17),
        title: const Text('Spiel verlassen?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Das laufende Spiel wird beendet und nicht gewertet. Wirklich zurück zum Menü?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Color.fromARGB(255, 215, 198, 132))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Verlassen',
                style: TextStyle(color: Color.fromARGB(255, 215, 198, 132))),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          // ########## Top row with logo, game title and back button
          const SizedBox(height: 20),
          Expanded(
            flex: 10,
            child: Header(
              gameName: widget.title,
              onBack: () => _onBack(context),
            ),
          ),

          // ########## Main part with game content
          Expanded(
            flex: 70,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(child: widget.mainContent),
              ],
            ),
          ),

          // ########## Bottom row with stats
          Expanded(
            flex: 20,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.statsContent),
                      if (_showHighscoreIcon)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: IconButton(
                            icon: const Icon(Icons.emoji_events,
                                color: Color.fromARGB(255, 215, 198, 132)),
                            tooltip: 'Highscores',
                            onPressed: () => _openHighscores(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
