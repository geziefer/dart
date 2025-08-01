import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/checknumber.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:flutter/material.dart';
import 'package:dart/widget/checkout.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewRTCX extends StatelessWidget {
  const ViewRTCX({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem = ModalRoute.of(context)?.settings.arguments as MenuItem?;
    
    ControllerRTCX controller = Provider.of<ControllerRTCX>(context);
    
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
            flex: 72,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(
                  child: Row(
                    children: [
                      // ########## Left column with game results
                      Expanded(
                        flex: 5,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // ########## 5 x 4 items for all numbers
                            children: [
                              for (int i = 1; i <= 3; i++)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    for (int j = 1; j <= 7; j++)
                                      CheckNumber(
                                        currentNumber:
                                            controller.getCurrentNumber(),
                                        number: (i - 1) * 7 + j,
                                      )
                                  ],
                                ),
                            ],
                          ),
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
            flex: 18,
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
                      "${currentStats['throw']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "   ØDarts/Checkout: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['avgChecks']}",
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
