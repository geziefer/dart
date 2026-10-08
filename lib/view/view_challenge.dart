import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/controller/controller_challenge.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/view/view_rtcx.dart';
import 'package:dart/view/view_shootx.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/widget/highscore_dialog.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ViewChallenge extends StatefulWidget {
  const ViewChallenge({super.key, required this.title});

  final String title;

  @override
  State<ViewChallenge> createState() => _ViewChallengeState();
}

class _ViewChallengeState extends State<ViewChallenge> {
  @override
  void initState() {
    super.initState();
    // Keep screen on for the entire challenge — sub-game GameLayouts would
    // otherwise briefly disable the wake lock between stage transitions.
    // Skip on web: wakelock_plus' no_sleep.js throws a non-fatal TypeError.
    if (!kIsWeb) WakelockPlus.enable();
  }

  @override
  void dispose() {
    if (!kIsWeb) WakelockPlus.disable();
    super.dispose();
  }

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

        // Delegate to the appropriate sub-game view based on current stage.
        final Widget subView;
        switch (controller.currentStage) {
          case 0:
          case 1:
            subView = ChangeNotifierProvider<ControllerRTCX>.value(
              value: controller.currentController as ControllerRTCX,
              child: const ViewRTCX(title: 'RTCX Singles'),
            );
            break;
          case 2:
            subView = ChangeNotifierProvider<ControllerShootx>.value(
              value: controller.currentController as ControllerShootx,
              child: const ViewShootx(title: 'Shoot 20'),
            );
            break;
          case 3:
            subView = ChangeNotifierProvider<ControllerShootx>.value(
              value: controller.currentController as ControllerShootx,
              child: const ViewShootx(title: 'Shoot Bull'),
            );
            break;
          case 4:
            subView = ChangeNotifierProvider<ControllerXXXCheckout>.value(
              value: controller.currentController as ControllerXXXCheckout,
              child: const ViewXXXCheckout(title: '501 Checkout'),
            );
            break;
          default:
            subView = const Scaffold(
              body: Center(child: Text('Prüfung abgeschlossen')),
            );
        }

        // Overlay a persistent trophy opening the Challenge's own medal
        // highscore list, placed bottom-right to match every other game. The
        // Challenge sub-games run with unconfigured highscore ids
        // (e.g. 'challenge_rtcx_0'), so their GameLayout shows no trophy of its
        // own — the bottom-right corner is free for the Challenge trophy.
        return Stack(
          children: [
            subView,
            Positioned(
              bottom: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.emoji_events,
                      color: Color.fromARGB(255, 215, 198, 132)),
                  tooltip: 'Sportabzeichen Highscores',
                  onPressed: () => _openChallengeHighscores(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openChallengeHighscores(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const HighscoreDialog(
        gameId: 'CHALLENGE',
        gameName: 'Bayrisches Sportabzeichen',
      ),
    );
  }
}
