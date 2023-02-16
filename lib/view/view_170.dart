import 'package:dart/controller/controller_170.dart';
import 'package:dart/view/header.dart';
import 'package:dart/view/numpad.dart';
import 'package:dart/view/scorecolumn.dart';
import 'package:flutter/material.dart';

class View170 extends StatelessWidget {
  const View170({super.key});

  @override
  Widget build(BuildContext context) {
    Controller170 controller = Controller170();
    Map stats = controller.getCurrentStats();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          // ########## Top row with logo, game title and back button
          const Expanded(
            flex: 1,
            child: Header(label: '170'),
          ),

          // ########## Main part with game results and num pad
          Expanded(
            flex: 8,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(
                  child: Row(
                    children: [
                      // ########## Left column with game results
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            const SizedBox(width: 50),
                            // ########## Throw number
                            ScoreColumn(
                                label: 'A',
                                content: controller.getCurrentRounds(),
                                color:
                                    const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Thrown score in round
                            ScoreColumn(
                              label: 'W',
                              content: controller.getCurrentScores(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Score left
                            ScoreColumn(
                              label: 'R',
                              content: controller.getCurrentRemainings(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Darts thrown
                            ScoreColumn(
                                label: 'D',
                                content: controller.getCurrentDarts(),
                                color:
                                    const Color.fromARGB(255, 215, 198, 132)),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with num pad
                      const Expanded(
                        flex: 5,
                        child: Numpad(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white, thickness: 3),
              ],
            ),
          ),

          // ########## Bottom row with stats
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Runde: ",
                  style: TextStyle(
                      fontSize: 36, color: Color.fromARGB(255, 215, 198, 132)),
                ),
                Text(
                  "${stats['round']}",
                  style: const TextStyle(fontSize: 36, color: Colors.white),
                ),
                const Text(
                  "   Ø Punkte: ",
                  style: TextStyle(
                      fontSize: 36, color: Color.fromARGB(255, 215, 198, 132)),
                ),
                Text(
                  "${stats['avgScore']}",
                  style: const TextStyle(fontSize: 36, color: Colors.white),
                ),
                const Text(
                  "   Ø Darts: ",
                  style: TextStyle(
                      fontSize: 36, color: Color.fromARGB(255, 215, 198, 132)),
                ),
                Text(
                  "${stats['avgDarts']}",
                  style: const TextStyle(fontSize: 36, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
