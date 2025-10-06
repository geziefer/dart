import 'package:dart/controller/controller_doublepath.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewDoublePath extends StatelessWidget {
  const ViewDoublePath({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerDoublePath controller =
        Provider.of<ControllerDoublePath>(context);

    // Set up callbacks for UI interactions
    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
    String stats = controller.getStats();

    return GameLayout(
      title: title,
      mainContent: Column(
        children: [
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
                        label: 'C',
                        content: controller.getCurrentPoints(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(
                          color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),

                      // ########## Total points
                      ScoreColumn(
                        label: 'P',
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

                // ########## Right column with custom num pad
                Expanded(
                  flex: 5,
                  child: Numpad(
                    controller: controller,
                    showUpper: false,
                    showMiddle: false,
                    showLower: true, // shows 1, 2, 3
                    showExtraButtons: false,
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
                "  Punkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                (controller.totalPoints.isNotEmpty
                        ? controller.totalPoints.last
                        : 0)
                    .toString(),
                style: statsNumberTextStyle(context),
              ),
              Text(
                "  ØPunkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                controller.currentRound > 0
                    ? ((controller.totalPoints.isNotEmpty
                                ? controller.totalPoints.last
                                : 0) /
                            controller.currentRound)
                        .toStringAsFixed(1)
                    : '0.0',
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
