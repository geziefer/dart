import 'package:dart/interfaces/numpad_controller.dart';
import 'package:duration_button/duration_button.dart';
import 'package:flutter/material.dart';

class Checkout extends StatelessWidget {
  const Checkout({
    super.key,
    required this.remaining,
    required this.controller,
  });

  final int remaining;
  final NumpadController controller;

  @override
  Widget build(BuildContext context) {
    if (remaining > 0) {
      return SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.all(5),
              child: const Text(
                "Maximale Dart-Anzahl erreicht",
                style: TextStyle(fontSize: 40, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              child: DurationButton(
                duration: const Duration(seconds: 3),
                onPressed: () {
                  Navigator.pop(context);
                },
                coverColor: Colors.black,
                backgroundColor: Colors.grey[800],
                width: 150,
                height: 80,
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
    return SizedBox(
      height: 250,
      width: 550,
      child: Column(
        children: [
          const Text(
            "Wie viele Darts zum Checkout?",
            style: TextStyle(fontSize: 40, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    child: TextButton(
                      onPressed: () {
                        // correct previously counted 3 darts to 1
                        controller.correctDarts(2);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(
                        "1",
                        style: TextStyle(fontSize: 50, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    child: TextButton(
                      onPressed: () {
                        // correct previously counted 3 darts to 2
                        controller.correctDarts(1);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(
                        "2",
                        style: TextStyle(fontSize: 50, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    child: TextButton(
                      onPressed: () {
                        // nothing to correct, but call for update
                        controller.correctDarts(0);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(
                        "3",
                        style: TextStyle(fontSize: 50, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
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
