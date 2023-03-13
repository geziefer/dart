import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Summary extends StatelessWidget {
  const Summary({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ControllerXXXCheckout controller =
        Provider.of<ControllerXXXCheckout>(context);
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.all(5),
            child: const Text(
              "Zusammenfassung",
              style: TextStyle(fontSize: 50, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
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
                minimumSize: const Size(150, 80),
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
    );
  }
}
