import 'package:dart/controller/controller_speedbull.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:flutter/material.dart';
import 'package:dart/widget/checkout.dart';
import 'package:provider/provider.dart';

class ViewSpeedBull extends StatelessWidget {
  const ViewSpeedBull({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerSpeedBull controller = Provider.of<ControllerSpeedBull>(context);
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
                                    style: timerTextStyle,
                                  ),
                                  const SizedBox(height: 20),
                                  if (!controller.gameStarted && !controller.gameEnded)
                                    ElevatedButton(
                                      onPressed: () => controller.startGame(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 215, 198, 132),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                      ),
                                      child: const Text(
                                        'START',
                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                                      const Text(
                                        "Runde: ",
                                        style: statsTextStyle,
                                      ),
                                      Text(
                                        "${currentStats['rounds']}",
                                        style: statsNumberTextStyle,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Punkte: ",
                                        style: statsTextStyle,
                                      ),
                                      Text(
                                        "${currentStats['totalHits']}",
                                        style: statsNumberTextStyle,
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
                      "Runde: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['rounds']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  Punkte: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['totalHits']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "  ØPunkte: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['average']}",
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
