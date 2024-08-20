import 'package:dart/controller/controller_finishes.dart';
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(100, 5, 5, 5),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.getQuestionText(),
                                  style: const TextStyle(
                                    fontSize: 70,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  controller.getSolutionText(),
                                  style: const TextStyle(
                                    fontSize: 70,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    controller.toggle();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        width: 3.0, color: Colors.white),
                                  ),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                        fontSize: 50, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ]),
                        ),
                      ),
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with num pad
                      const Expanded(
                        flex: 5,
                        child: Text(''),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white, thickness: 3),
              ],
            ),
          ),

          // ########## Bottom row with stats
          const Expanded(
            flex: 18,
            child: Column(
              children: [],
            ),
          ),
        ],
      ),
    );
  }
}
