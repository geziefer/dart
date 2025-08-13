import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/widget/fullcircle.dart';
import 'package:dart/widget/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart/widget/menu.dart';

class ViewFinishes extends StatelessWidget {
  const ViewFinishes({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    // Get the MenuItem from route arguments
    final MenuItem? menuItem =
        ModalRoute.of(context)?.settings.arguments as MenuItem?;

    ControllerFinishes controller = Provider.of<ControllerFinishes>(context);

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
                                // Result symbol and time in separate widgets
                                Row(
                                  children: [
                                    // Round counter
                                    Text(
                                      '${controller.getRoundCounterText()} ',
                                      style: outputTextStyle(context),
                                    ),
                                    Text(
                                      controller.getResultSymbol(),
                                      style: emojiTextStyle(context),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      ' ${controller.getResultTime()}',
                                      style: outputTextStyle(context),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                // Preferred finish question
                                Text(
                                  controller.getPreferredText(),
                                  style: outputTextStyle(context),
                                ),
                                // Preferred finish input
                                Text(
                                  controller.getPreferredInput(),
                                  style: inputTextStyle(context),
                                ),
                                // Alternative finish question
                                Text(
                                  controller.getAlternativeText(),
                                  style: outputTextStyle(context),
                                ),
                                // Alternative finish input
                                Text(
                                  controller.getAlternativeInput(),
                                  style: inputTextStyle(context),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),

                                // Solution text when incorrect
                                Text(
                                  controller.getSolutionText(),
                                  style: outputTextStyle(context),
                                ),
                              ]),
                        ),
                      ),
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with dart board
                      Expanded(
                        flex: 6,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate the available space for the dartboard
                            // Use the smaller dimension to ensure it fits, with padding
                            double availableWidth = constraints.maxWidth;
                            double availableHeight = constraints.maxHeight;
                            double maxSize = (availableWidth < availableHeight
                                    ? availableWidth
                                    : availableHeight) -
                                40; // 40px total padding

                            // Calculate radius (dartboard diameter should fit in maxSize)
                            // Account for the number labels that extend beyond the circle
                            double radius =
                                (maxSize - 60) / 2; // 60px for number labels

                            // Make radius bounds responsive to screen size
                            final isPhone =
                                ResponsiveUtils.isPhoneSize(context);
                            final minRadius = isPhone
                                ? 110.0
                                : 200.0; // Slightly reduced from 120 to 110
                            final maxRadius = isPhone
                                ? 170.0
                                : 280.0; // Slightly reduced from 180 to 170

                            // Ensure minimum and maximum bounds based on device type
                            radius = radius.clamp(minRadius, maxRadius);

                            return Stack(
                              children: [
                                // Undo button at very left and bottom corner of the area
                                Positioned(
                                  left: 15,
                                  bottom: 15,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: IconButton(
                                      onPressed: controller.canUndo()
                                          ? () => controller.undoLastInput()
                                          : null,
                                      icon: Icon(
                                        Icons.undo,
                                        color: controller.canUndo()
                                            ? Colors.white
                                            : Colors.grey[600],
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                                // Centered dartboard
                                Center(
                                  child: Stack(
                                    children: [
                                      // Dartboard
                                      FullCircle(
                                        controller: controller,
                                        radius: radius,
                                        arcSections: [
                                          ArcSection(startPercent: 0.2),
                                          ArcSection(startPercent: 0.4),
                                          ArcSection(startPercent: 0.6),
                                          ArcSection(startPercent: 0.8),
                                        ],
                                      ),
                                      // Full dartboard overlay button when waiting for next round
                                      if (controller.waitingForNextRound)
                                        Positioned.fill(
                                          child: GestureDetector(
                                            onTap: () =>
                                                controller.startNextRound(),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Nächste Runde",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: ResponsiveUtils
                                                        .getResponsiveFontSize(
                                                            context, 28),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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
                    Text(
                      "Richtig: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      "${currentStats['correct']} (${currentStats['percentage']}%)",
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "   Zeit: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      "${currentStats['totalTime']}s",
                      style: statsNumberTextStyle(context),
                    ),
                    Text(
                      "   ØZeit: ",
                      style: statsTextStyle(context),
                    ),
                    Text(
                      "${currentStats['averageTime']}s",
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
