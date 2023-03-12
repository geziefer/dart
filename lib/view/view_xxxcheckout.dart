import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewXXXCheckout extends StatelessWidget {
  const ViewXXXCheckout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ControllerXXXCheckout controller =
        Provider.of<ControllerXXXCheckout>(context);
    Map stats = controller.getCurrentStats();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          // ########## Top row with logo, game title and back button
          const SizedBox(height: 20),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                      Expanded(
                        flex: 5,
                        child: Numpad(controller: controller),
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
                      fontSize: 50, color: Color.fromARGB(255, 215, 198, 132)),
                ),
                Text(
                  "${stats['round']}",
                  style: const TextStyle(fontSize: 50, color: Colors.white),
                ),
                const Text(
                  "   Ø Punkte: ",
                  style: TextStyle(
                      fontSize: 50, color: Color.fromARGB(255, 215, 198, 132)),
                ),
                Text(
                  "${stats['avgScore']}",
                  style: const TextStyle(fontSize: 50, color: Colors.white),
                ),
                const Text(
                  "   Ø Darts: ",
                  style: TextStyle(
                      fontSize: 50, color: Color.fromARGB(255, 215, 198, 132)),
                ),
                Text(
                  "${stats['avgDarts']}",
                  style: const TextStyle(fontSize: 50, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}