import 'package:dart/controller/controller_updown.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewUpDown extends StatelessWidget {
  const ViewUpDown({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem =
        ModalRoute.of(context)?.settings.arguments as MenuItem?;

    ControllerUpDown controller = Provider.of<ControllerUpDown>(context);

    // Initialize the controller if not already initialized
    if (controller.item == null && menuItem != null) {
      controller.init(menuItem);
    }
    // Set up callbacks for UI interactions
    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
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
                            // ########## Round numbers
                            ScoreColumn(
                                label: 'R',
                                content: controller.getCurrentRounds(),
                                color:
                                    const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Target values
                            ScoreColumn(
                              label: 'Z',
                              content: controller.getCurrentTargets(),
                              color: const Color.fromARGB(255, 215, 198, 132),
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Results (success/failure emojis)
                            ScoreColumn(
                              label: 'C',
                              content: controller.getCurrentResults(),
                              color: const Color.fromARGB(255, 132, 215, 132),
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with yes/no numpad
                      Expanded(
                        flex: 5,
                        child: Numpad(
                          controller: controller,
                          showUpper: false,
                          showMiddle: false,
                          showLower: false,
                          showExtraButtons: false,
                          showYesNo: true, // Only yes/no buttons plus undo
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
                    Text(
                      "Runde: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      currentStats['round'].toString(),
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "  Ziel: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      currentStats['target'].toString(),
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "  Checks: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      currentStats['successes'].toString(),
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "  ØChecks: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      (currentStats['averageSuccess'] as double)
                          .toStringAsFixed(1),
                      style: statsNumberTextStyle(context),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats,
                      style: statsSummaryTextStyle(context),
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
