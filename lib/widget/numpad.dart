import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/material.dart';

/// Build 4x3 numpad 0-9, undo, return
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.controller,
    required this.fullSelection,
  });

  final NumpadController controller;
  final bool fullSelection; // flag if only 1-3 buttons are shown

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          // ########## input
          child: Column(
            children: [
              Text(
                controller.getInput(),
                style: const TextStyle(
                  fontSize: 70,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white, thickness: 3),
            ],
          ),
        ),
        if (fullSelection)
          Expanded(
            flex: 1,
            // ########## 1st row 7, 8, 9
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NumpadButton(
                  label: '7',
                  value: 7,
                  controller: controller,
                ),
                NumpadButton(
                  label: '8',
                  value: 8,
                  controller: controller,
                ),
                NumpadButton(
                  label: '9',
                  value: 9,
                  controller: controller,
                ),
              ],
            ),
          ),
        if (fullSelection)
          Expanded(
            flex: 1,
            // ########## 2nd row 4, 5, 6
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NumpadButton(
                  label: '4',
                  value: 4,
                  controller: controller,
                ),
                NumpadButton(
                  label: '5',
                  value: 5,
                  controller: controller,
                ),
                NumpadButton(
                  label: '6',
                  value: 6,
                  controller: controller,
                ),
              ],
            ),
          ),
        Expanded(
          flex: 1,
          // ########## 3rd row 1, 2, 3
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NumpadButton(
                label: '1',
                value: 1,
                controller: controller,
              ),
              NumpadButton(
                label: '2',
                value: 2,
                controller: controller,
              ),
              NumpadButton(
                label: '3',
                value: 3,
                controller: controller,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          // ########## 4th row back, 0, enter
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NumpadButton(
                label: '↶',
                value: -2,
                controller: controller,
              ),
              NumpadButton(
                label: '0',
                value: 0,
                controller: controller,
              ),
              NumpadButton(
                label: '↵',
                value: -1,
                controller: controller,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Builds 1 field of num pad to enter score
class NumpadButton extends StatelessWidget {
  const NumpadButton({
    super.key,
    required this.label,
    required this.value,
    required this.controller,
  });

  final String label;
  final int value; // numbers 0 - 9, -1: enter, -2: undo
  final NumpadController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: TextButton(
          onPressed: () {
            controller.pressNumpadButton(context, value);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white24,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 50, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
