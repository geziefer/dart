import 'package:dart/controller/controller_creditfinish.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
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

          // ########## Main part with results table and num pad
          Expanded(
            flex: 72,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
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
                            
                            // ########## Result
                            ScoreColumn(
                              label: 'C',
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
                const Divider(color: Colors.white, thickness: 3),
              ],
            ),
          ),

          // ########## Bottom row with stats
          Expanded(
            flex: 18,
            child: Column(
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
          ),
        ],
      ),
    );
  }
}
