import 'package:flutter/material.dart';
import 'package:dart/widget/header.dart';
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
  });

  final String title;
  final Widget mainContent;
  final Widget statsContent;

  @override
  State<GameLayout> createState() => _GameLayoutState();
}

class _GameLayoutState extends State<GameLayout> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
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
            child: Header(gameName: widget.title),
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
                Expanded(child: widget.statsContent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
