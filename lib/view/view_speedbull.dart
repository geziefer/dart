import 'package:dart/controller/controller_speedbull.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewSpeedBull extends StatelessWidget {
  const ViewSpeedBull({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem =
        ModalRoute.of(context)?.settings.arguments as MenuItem?;

    ControllerSpeedBull controller = Provider.of<ControllerSpeedBull>(context);

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
      mainContent: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // ########## Timer and Start Button
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.getTimerDisplay(),
                        style: timerTextStyle(context),
                      ),
                      const SizedBox(height: 20),
                      if (!controller.gameStarted &&
                          !controller.gameEnded)
                        ElevatedButton(
                          onPressed: () => controller.startGame(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                                255, 215, 198, 132),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            'START',
                            style: TextStyle(
                                fontSize: ResponsiveUtils
                                    .getResponsiveFontSize(
                                        context, 24),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white, thickness: 1),
                // ########## Game Stats
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Runde: ",
                            style: statsTextStyle(context),
                          ),
                          Text(
                            "${currentStats['rounds']}",
                            style: statsNumberTextStyle(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Punkte: ",
                            style: statsTextStyle(context),
                          ),
                          Text(
                            "${currentStats['totalHits']}",
                            style: statsNumberTextStyle(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
              showMiddle: false,
              showLower: true,
              showExtraButtons: false,
              showYesNo: false,
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
                "${currentStats['rounds']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "  Punkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['totalHits']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "  ØPunkte: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['average']}",
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
