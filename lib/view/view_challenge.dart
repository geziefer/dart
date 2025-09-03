import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/controller/controller_challenge.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/view/view_rtcx.dart';
import 'package:dart/view/view_shootx.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/summary_dialog.dart';

class ViewChallenge extends StatefulWidget {
  const ViewChallenge({super.key, required this.title});

  final String title;

  @override
  State<ViewChallenge> createState() => _ViewChallengeState();
}

class _ViewChallengeState extends State<ViewChallenge> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ControllerChallenge>(
      builder: (context, controller, child) {
        // Set up callbacks
        controller.onGameEnded = () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return SummaryDialog(
                lines: controller.createSummaryLines(),
                onOk: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to menu
                },
              );
            },
          );
        };

        // Delegate sub-game callbacks to current controller
        if (controller.currentController != null) {
          controller.currentController.onShowCheckout = (remaining, score) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return SummaryDialog(
                  lines: controller.currentController.createSummaryLines(),
                  onOk: () {
                    Navigator.of(context).pop(); // Only pop the dialog
                    controller.currentController.handleCheckoutClosed?.call();
                  },
                );
              },
            );
          };
        }

        // Return the appropriate sub-game view
        if (controller.currentController == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Delegate to the appropriate sub-game view based on current stage
        switch (controller.currentStage) {
          case 0:
          case 1:
            return ChangeNotifierProvider<ControllerRTCX>.value(
              value: controller.currentController as ControllerRTCX,
              child: const ViewRTCX(title: 'RTCX Singles'),
            );
          case 2:
            return ChangeNotifierProvider<ControllerShootx>.value(
              value: controller.currentController as ControllerShootx,
              child: const ViewShootx(title: 'Shoot 20'),
            );
          case 3:
            return ChangeNotifierProvider<ControllerShootx>.value(
              value: controller.currentController as ControllerShootx,
              child: const ViewShootx(title: 'Shoot Bull'),
            );
          case 4:
            return ChangeNotifierProvider<ControllerXXXCheckout>.value(
              value: controller.currentController as ControllerXXXCheckout,
              child: const ViewXXXCheckout(title: '501 Checkout'),
            );
          default:
            return const Scaffold(
              body: Center(child: Text('Challenge Complete')),
            );
        }
      },
    );
  }
}
