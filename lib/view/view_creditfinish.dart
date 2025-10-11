import 'package:dart/controller/controller_creditfinish.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewCreditFinish extends StatelessWidget {
  const ViewCreditFinish({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem =
        ModalRoute.of(context)?.settings.arguments as MenuItem?;

    ControllerCreditFinish controller = Provider.of<ControllerCreditFinish>(context);

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
    GamePhase currentPhase = controller.getCurrentPhase();
    
    return GameLayout(
      title: title,
      mainContent: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // ########## Left column with score columns
                Expanded(
                  flex: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ########## Round number
                      ScoreColumn(
                        label: 'P',
                        content: controller.getCurrentRounds(),
                        color: const Color.fromARGB(255, 215, 198, 132),
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),
                      
                      // ########## Score
                      ScoreColumn(
                        label: 'R',
                        content: controller.getCurrentScores(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),
                      
                      // ########## Credits
                      ScoreColumn(
                        label: 'C',
                        content: controller.getCurrentCredits(),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const VerticalDivider(color: Colors.white, thickness: 1),
                      const SizedBox(width: 10),
                      
                      // ########## Result
                      ScoreColumn(
                        label: 'F',
                        content: controller.getCurrentResults(),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(color: Colors.white, thickness: 3),

                // ########## Right column with num pad
                Expanded(
                  flex: 55,
                  child: Numpad(
                    controller: controller,
                    showUpper: currentPhase == GamePhase.scoreInput,
                    showMiddle: currentPhase == GamePhase.scoreInput,
                    showLower: currentPhase == GamePhase.scoreInput,
                    showExtraButtons: currentPhase == GamePhase.scoreInput,
                    showYesNo: currentPhase == GamePhase.finishInput,
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
                "Checks: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['checks']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "   Misses: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['misses']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "   Ø Checks: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['rounds'] > 0 ? ((currentStats['checks'] as int) / (currentStats['rounds'] as int) * 100).toStringAsFixed(1) : '0.0'}%",
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
