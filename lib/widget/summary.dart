import 'package:dart/controller/controller_170.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Summary extends StatelessWidget {
  const Summary({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Controller170 controller = Provider.of<Controller170>(context);
    return SizedBox(
      height: 750,
      width: 450,
      child: Column(
        children: [
          const Text(
            "Zusammenfassung",
            style: TextStyle(fontSize: 50, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.all(5),
                  child: Text(
                    controller.createMultilineString(
                        controller.results, 'Leg', 'Darts', 10, true),
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  child: Text(
                    'Ø Punkte: ${controller.getCurrentStats()['avgScore']}\nØ Darts: ${controller.getCurrentStats()['avgDarts']}',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(5),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 50, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
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
