import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/styles.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/widget/fullcircle.dart';
import 'package:dart/widget/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewFinishes extends StatelessWidget {
  const ViewFinishes({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    ControllerFinishes controller = Provider.of<ControllerFinishes>(context);
    Map currentStats = controller.getCurrentStats();
    String stats = controller.getStats();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          // ########## Top row with logo, game title, stats and back button
          const SizedBox(height: 20),
          Expanded(
            flex: 1,
            child: Header(gameName: title),
          ),

          // ########## Main part with game results and dart board
          Expanded(
            flex: 7,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(100, 5, 5, 5),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Round counter
                                Text(
                                  controller.getRoundCounterText(),
                                  style: roundCounterTextStyle,
                                ),
                                const SizedBox(height: 20),
                                // Preferred finish question
                                Text(
                                  controller.getPreferredText(),
                                  style: outputTextStyle,
                                ),
                                // Preferred finish input
                                Text(
                                  controller.getPreferredInput(),
                                  style: inputTextStyle,
                                ),
                                // Alternative finish question
                                Text(
                                  controller.getAlternativeText(),
                                  style: outputTextStyle,
                                ),
                                // Alternative finish input
                                Text(
                                  controller.getAlternativeInput(),
                                  style: inputTextStyle,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                // Result (✅/❌ with time)
                                Text(
                                  controller.getResultText(),
                                  style: outputTextStyle,
                                ),
                                // Solution text when incorrect
                                Text(
                                  controller.getSolutionText(),
                                  style: inputTextStyle,
                                ),
                              ]),
                        ),
                      ),
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with dart board
                      Expanded(
                        flex: 6,
                        child: FullCircle(
                          controller: controller,
                          radius: 300,
                          arcSections: [
                            ArcSection(startPercent: 0.2),
                            ArcSection(startPercent: 0.4),
                            ArcSection(startPercent: 0.6),
                            ArcSection(startPercent: 0.8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ########## Bottom row with current stats
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const Divider(color: Colors.white, thickness: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Richtig: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['correct']}",
                      style: statsNumberTextStyle,
                    ),
                    const Text(
                      "   Korrektheit: ",
                      style: statsTextStyle,
                    ),
                    Text(
                      "${currentStats['percentage']}%",
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
