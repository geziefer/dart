import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewCatchXX extends StatelessWidget {
  const ViewCatchXX({
    super.key,
    required this.gameno,
  });

  final int gameno;

  @override
  Widget build(BuildContext context) {
    ControllerCatchXX controller = Provider.of<ControllerCatchXX>(context);
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
            child: Header(gameno: gameno),
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
                            // ########## Target
                            ScoreColumn(
                                label: 'Z',
                                content: controller.getCurrentTargets(),
                                color:
                                    const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Thrown points in round
                            ScoreColumn(
                              label: 'C',
                              content: controller.getCurrentThrownPoints(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Score total
                            ScoreColumn(
                              label: 'T',
                              content: controller.getCurrentTotalPoints(),
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
                          showUpper: false,
                          showMiddle: true,
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
                      "Ziel: ",
                      style: TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['target']}",
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                    const Text(
                      "  Punkte: ",
                      style: TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['points']}",
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                    const Text(
                      "   ØPunkte: ",
                      style: TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['avgPoints']}",
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
