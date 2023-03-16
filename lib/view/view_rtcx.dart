import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/widget/checknumber.dart';
import 'package:dart/widget/header.dart';
import 'package:dart/widget/numpad.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewRTCX extends StatelessWidget {
  const ViewRTCX({
    super.key,
    required this.gameno,
  });

  final int gameno;

  @override
  Widget build(BuildContext context) {
    ControllerRTCX controller = Provider.of<ControllerRTCX>(context);
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
            child: Header(gameno: gameno),
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
                      const VerticalDivider(color: Colors.white, thickness: 3),

                      // ########## Right column with num pad
                      Expanded(
                        flex: 5,
                        child: Numpad(
                          controller: controller,
                          fullSelection: false,
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
                      style: TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['throw']}",
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                    const Text(
                      "   ØDarts/Checkout: ",
                      style: TextStyle(
                          fontSize: 50,
                          color: Color.fromARGB(255, 215, 198, 132)),
                    ),
                    Text(
                      "${currentStats['avgChecks']}",
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats,
                      style: const TextStyle(fontSize: 40, color: Colors.white),
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
