import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:dart/widget/checkout.dart';
import 'package:provider/provider.dart';

class ViewCatchXX extends StatelessWidget {
  const ViewCatchXX({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerCatchXX controller = Provider.of<ControllerCatchXX>(context);
    // Set up callbacks for UI interactions
    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
    controller.onShowCheckout = (remaining) {
      // Show checkout dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2))),
            child: Checkout(
              remaining: remaining,
              controller: controller,
            ),
          );
        },
      );
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
                      "${currentStats['hits']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  Punkte: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['points']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "   ØPunkte: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['avgPoints']}",
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
