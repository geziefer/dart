import 'package:dart/controller/controller_bigts.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewBigTs extends StatelessWidget {
  const ViewBigTs({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerBigTs controller = Provider.of<ControllerBigTs>(context);

    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
    String stats = controller.getStats();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 10,
            child: Header(gameName: title),
          ),
          Expanded(
            flex: 70,
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
                            ScoreColumn(
                                label: 'R',
                                content: controller.getCurrentTargets(),
                                color: const Color.fromARGB(255, 215, 198, 132)),
                            const SizedBox(width: 10),
                            const VerticalDivider(color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),
                            ScoreColumn(
                              label: 'C',
                              content: controller.getCurrentPoints(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(color: Colors.white, thickness: 1),
                            const SizedBox(width: 10),
                            ScoreColumn(
                              label: 'P',
                              content: controller.getCurrentTotalPoints(),
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
                const Divider(color: Colors.white, thickness: 3),
              ],
            ),
          ),
          Expanded(
            flex: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("  Punkte: ", style: statsTextStyle(context)),
                    Text(
                      (controller.totalPoints.isNotEmpty ? controller.totalPoints.last : 0).toString(),
                      style: statsNumberTextStyle(context),
                    ),
                    Text("  ØPunkte: ", style: statsTextStyle(context)),
                    Text(
                      controller.currentRound > 0
                          ? ((controller.totalPoints.isNotEmpty ? controller.totalPoints.last : 0) / controller.currentRound).toStringAsFixed(1)
                          : '0.0',
                      style: statsNumberTextStyle(context),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(stats, style: statsSummaryTextStyle(context)),
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
