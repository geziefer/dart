import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewShootx extends StatelessWidget {
  const ViewShootx({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem =
        ModalRoute.of(context)?.settings.arguments as MenuItem?;

    ControllerShootx controller = Provider.of<ControllerShootx>(context);

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
                        label: 'T',
                        content: controller.getCurrentThrownNumbers(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(
                          color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),

                      // ########## Score total
                      ScoreColumn(
                        label: 'P',
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
                "${currentStats['round']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "   ØT: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['avgHits']}",
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
