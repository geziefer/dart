import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewShootx extends StatelessWidget {
  const ViewShootx({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerShootx controller = Provider.of<ControllerShootx>(context);
    int x = controller.x;
    Map currentStats = controller.getCurrentStats();
    String stats = controller.getStats();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          // ########## Top row with logo, game title, stats and back button
          const SizedBox(height: 20),
          Expanded(
            flex: 10,
            child: Header(gameName: title),
          ),

          // ########## Main part with game results and num pad
          Expanded(
            flex: 72,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ########## Round number
                            ScoreColumn(
                                label: 'R',
                                content: controller.getCurrentRounds(),
                                color:
                                    const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Thrown numbers in round
                            ScoreColumn(
                              label: 'N',
                              content: controller.getCurrentThrownNumbers(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Score total
                            ScoreColumn(
                              label: 'T',
                              content: controller.getCurrentTotalNumbers(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with num pad
                      Expanded(
                        flex: 5,
                        child: Numpad(
                          controller: controller,
                          showUpper: true,
                          showMiddle: true,
                          showExtraButtons: false,
                          showYesNo: false,
                        ),
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
            flex: 18,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Runde: ",
                      style: TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['round']}",
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                    Text(
                      "   Ø$x: ",
                      style: const TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['avgBulls']}",
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats,
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
