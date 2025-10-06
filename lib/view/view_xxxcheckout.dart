import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:dart/widget/checkout.dart';
import 'package:provider/provider.dart';

class ViewXXXCheckout extends StatelessWidget {
  const ViewXXXCheckout({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerXXXCheckout controller =
        Provider.of<ControllerXXXCheckout>(context);

    // Set up callbacks for UI interactions
    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
    controller.onShowCheckout = (remaining, score) {
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
              score: score,
              onClosed: () => controller.onCheckoutClosed?.call(),
            ),
          );
        },
      );
    };
    controller.onCheckoutClosed = () {
      // Simply notify controller that checkout dialog is closed
      // Controller will handle any game end logic internally
      controller.handleCheckoutClosed();
    };
    Map currentStats = controller.getCurrentStats();
    String stats = controller.getStats();
    
    return GameLayout(
      title: title,
      mainContent: Column(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 45,
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
                  flex: 55,
                  child: Numpad(
                    controller: controller,
                    showUpper: true,
                    showMiddle: true,
                    showLower: true,
                    showExtraButtons: true,
                    showYesNo: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      statsContent: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Runde: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['round']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "   ØPunkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['avgScore']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "   ØDarts: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['avgDarts']}",
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
    );
  }
}
