import 'package:flutter/material.dart';
import 'package:dart/widget/header.dart';

class GameLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          // ########## Top row with logo, game title and back button
          const SizedBox(height: 20),
          Expanded(
            flex: 10,
            child: Header(gameName: title),
          ),

          // ########## Main part with game content
          Expanded(
            flex: 70,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(child: mainContent),
              ],
            ),
          ),

          // ########## Bottom row with stats
          Expanded(
            flex: 20,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(child: statsContent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
