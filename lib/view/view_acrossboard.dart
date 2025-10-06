import 'package:dart/controller/controller_acrossboard.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/target_sequence.dart';
import 'package:dart/widget/game_layout.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/checkout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewAcrossBoard extends StatelessWidget {
  const ViewAcrossBoard({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem =
        ModalRoute.of(context)?.settings.arguments as MenuItem?;

    ControllerAcrossBoard controller = Provider.of<ControllerAcrossBoard>(context);

    // Initialize the controller if not already initialized
    if (controller.item == null && menuItem != null) {
      controller.init(menuItem);
    }
    // Set up callbacks for UI interactions
    controller.onGameEnded = () {
      controller.showSummaryDialog(context);
    };
    controller.onShowCheckout = (remaining, score) {
      // Show checkout dialog in target mode
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
              score: score,
              isCheckoutMode: false, // Use target mode for Across Board
              onClosed: () => controller.onCheckoutClosed?.call(),
            ),
          );
        },
      );
    };
    controller.onCheckoutClosed = () {
      // Simply notify controller that checkout dialog is closed
      // Controller will handle game end logic internally
      controller.handleCheckoutClosed();
    };

    Map currentStats = controller.getCurrentStats();
    String stats = controller.getStats();
    
    return GameLayout(
      title: title,
      mainContent: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // ########## Left column with target sequence
                Expanded(
                  flex: 5,
                  child: TargetSequence(
                    targets: controller.getTargetSequence(),
                    targetsHit: controller.getTargetsHit(),
                    currentTargetIndex: controller.getCurrentTargetIndex(),
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
                "${currentStats['throw']}",
                style: statsNumberTextStyle(context),
              ),
              Text(
                "   ØDarts/Target: ",
                style: statsTextStyle(context),
              ),
              Text(
                "${currentStats['avgChecks']}",
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
