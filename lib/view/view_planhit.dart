import 'package:dart/controller/controller_planhit.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewPlanHit extends StatelessWidget {
  const ViewPlanHit({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerPlanHit controller = Provider.of<ControllerPlanHit>(context);

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
                      ScoreColumn(
                          label: 'Z',
                          content: controller.getCurrentTargets(),
                          color: const Color.fromARGB(255, 215, 198, 132)),
                      const SizedBox(width: 10),
                      const VerticalDivider(color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),

                      ScoreColumn(
                        label: 'T',
                        content: controller.getCurrentHits(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),

                      ScoreColumn(
                        label: 'P',
                        content: controller.getCurrentTotalHits(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                const VerticalDivider(color: Colors.white, thickness: 3),

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
                "${controller.currentRound}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "  Punkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                (controller.totalHits.isNotEmpty ? controller.totalHits.last : 0).toString(),
                style: statsNumberTextStyle(context),
              ),
              Text(
                "  ØPunkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                controller.currentRound > 0
                    ? ((controller.totalHits.isNotEmpty ? controller.totalHits.last : 0) / controller.currentRound).toStringAsFixed(1)
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
