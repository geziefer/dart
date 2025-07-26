import 'package:dart/controller/controller_check121.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewCheck121 extends StatelessWidget {
  const ViewCheck121({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerCheck121 controller = Provider.of<ControllerCheck121>(context);
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
            flex: 75,
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
                                color: const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Target
                            ScoreColumn(
                              label: 'Z',
                              content: controller.getCurrentTargets(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Attempts
                            ScoreColumn(
                              label: 'V',
                              content: controller.getCurrentAttempts(),
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
                          showMiddle: false,
                          showLower: true,
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
            flex: 15,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Ziel: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['target']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  Checks: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['successful']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  Misses: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['misses']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  Safe: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['savePoint']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  ØChecks: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['average']}",
                      style: statsNumberTextStyle,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats,
                      style: statsSummaryTextStyle,
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
