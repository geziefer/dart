import 'package:dart/controller/controller_bobs27.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:dart/widget/scorecolumn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewBobs27 extends StatelessWidget {
  const ViewBobs27({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerBobs27 controller = Provider.of<ControllerBobs27>(context);
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ########## Current Target
                            ScoreColumn(
                                label: 'T',
                                content: currentStats['target'],
                                color: Colors.yellow),
                            const SizedBox(width: 20),

                            // ########## Progress
                            ScoreColumn(
                                label: 'P',
                                content: currentStats['progress'],
                                color: Colors.blue),
                            const SizedBox(width: 20),

                            // ########## Current Score
                            ScoreColumn(
                                label: 'S',
                                content: currentStats['score'],
                                color: controller.totalScore > 0 
                                    ? Colors.green 
                                    : Colors.red),
                          ],
                        ),
                      ),

                      // ########## Numpad
                      Expanded(
                        flex: 3,
                        child: Numpad(
                          controller: controller,
                          showUpper: false,
                          showMiddle: false,
                          showExtraButtons: false,
                          showYesNo: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ########## Bottom row with stats
          Expanded(
            flex: 15,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Divider(color: Colors.white, thickness: 3),
                  Text(
                    stats,
                    style: statsTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
