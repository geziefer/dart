import 'package:dart/controller/controller_cricket.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/cricket_board.dart';
import 'package:dart/widget/checkout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewCricket extends StatelessWidget {
  const ViewCricket({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerCricket controller =
        Provider.of<ControllerCricket>(context);

    // Set up callbacks for UI interactions
    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
    
    controller.onShowCheckout = (remaining, score) {
      // Get last round hits to determine possible dart counts
      List<List<int>> allRoundHits = controller.getRoundHits;
      List<int> lastRoundHits = allRoundHits.isNotEmpty 
          ? allRoundHits[controller.getRound - 1] 
          : [];
      
      // Calculate possible dart counts based on distinct numbers hit
      Set<int> distinctNumbers = lastRoundHits.toSet();
      int bullCount = lastRoundHits.where((hit) => hit == 25).length;
      
      // Determine minimum darts needed
      int minDarts = distinctNumbers.length;
      
      // Special case for bull: if 3 bulls were hit, it cannot be done with 1 dart
      if (bullCount == 3 && distinctNumbers.length == 1) {
        minDarts = 2; // 3 bulls cannot be done with 1 dart
      }
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2))),
            child: Checkout(
              remaining: minDarts,
              controller: controller,
              score: 0,
              isCheckoutMode: false,
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

    Map<String, String> currentStats = controller.getCurrentStats();
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
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Cricket board display
                            CricketBoard(hits: controller.getHits),
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
                          showExtraButtons: false,
                          showYesNo: false,
                          cricketMode: true,
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
                      "Runde: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      "${currentStats['round']}",
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "   Darts: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      "${currentStats['darts']}",
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "   Übrig: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      "${currentStats['leftover']}",
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "   ØTreffer: ",
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
          ),
        ],
      ),
    );
  }
}
