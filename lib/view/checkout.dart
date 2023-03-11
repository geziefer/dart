import 'package:dart/controller/controller_170.dart';
import 'package:dart/view/numpad.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Checkout extends StatelessWidget {
  const Checkout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Controller170 controller = Provider.of<Controller170>(context);
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
                        controller.correctDarts(2);
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
                        // nothing to correct
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
