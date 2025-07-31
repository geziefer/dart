import 'package:dart/controller/controller_doublepath.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:dart/widget/checkout.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewDoublePath extends StatelessWidget {
  const ViewDoublePath({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem = ModalRoute.of(context)?.settings.arguments as MenuItem?;
    
    ControllerDoublePath controller =
        Provider.of<ControllerDoublePath>(context);
    
    // Initialize the controller if not already initialized
    if (controller.item == null && menuItem != null) {
      controller.init(menuItem);
    }
    
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
                            // ########## Target sequences
                            ScoreColumn(
                                label: 'Z',
                                content: controller.getCurrentTargets(),
                                color:
                                    const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Points per round
                            ScoreColumn(
                              label: 'P',
                              content: controller.getCurrentPoints(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                                color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),

                            // ########## Total points
                            ScoreColumn(
                              label: 'G',
                              content: controller.getCurrentTotalPoints(),
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

                      // ########## Right column with custom num pad
                      Expanded(
                        flex: 5,
                        child: Numpad(
                          controller: controller,
                          showUpper: false,
                          showMiddle: false,
                          showLower: true, // shows 1, 2, 3
                          showExtraButtons: true, // shows 0, back, enter
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
                      controller.currentRound < 5
                          ? ControllerDoublePath
                              .targetSequences[controller.currentRound]
                          : ControllerDoublePath.targetSequences[4],
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  Punkte: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      (controller.totalPoints.isNotEmpty
                              ? controller.totalPoints.last
                              : 0)
                          .toString(),
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  ØPunkte: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      controller.currentRound > 0
                          ? ((controller.totalPoints.isNotEmpty
                                      ? controller.totalPoints.last
                                      : 0) /
                                  controller.currentRound)
                              .toStringAsFixed(1)
                          : '0.0',
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
