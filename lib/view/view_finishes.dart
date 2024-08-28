import 'package:dart/controller/controller_finishes.dart';
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

          // ########## Main part with game results and num pad
          Expanded(
            flex: 9,
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
                                Text(
                                  controller.getPreferredText(),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  controller.getPreferredInput(),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  controller.getAlternativeText(),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  controller.getAlternativeInput(),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  controller.getResultText(),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  controller.getSolutionText(),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    color: Colors.white,
                                  ),
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
        ],
      ),
    );
  }
}
