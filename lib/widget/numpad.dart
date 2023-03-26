import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/material.dart';

/// Build 4x3 numpad 0-9, undo, return
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.controller,
    required this.showUpper,
    required this.showMiddle,
  });

  final NumpadController controller; // controller class which supports Numpad
  final bool showUpper; // flag if upper row 7-9 should be shown
  final bool showMiddle; // flag if middle row 4-6 should be shown

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
        if (showUpper)
          Expanded(
            flex: 1,
            // ########## 1st row 7, 8, 9
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 7; i <= 9; i++)
                  _buildNumpadButton(context, controller, i.toString(), i),
              ],
            ),
          ),
        if (showMiddle)
          Expanded(
            flex: 1,
            // ########## 2nd row 4, 5, 6
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 4; i <= 6; i++)
                  _buildNumpadButton(context, controller, i.toString(), i),
              ],
            ),
          ),
        Expanded(
          flex: 1,
          // ########## 3rd row 1, 2, 3
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 1; i <= 3; i++)
                _buildNumpadButton(context, controller, i.toString(), i),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          // ########## 4th row back, 0, enter
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNumpadButton(context, controller, '↶', -2),
              _buildNumpadButton(context, controller, '0', 0),
              _buildNumpadButton(context, controller, '↵', -1),
            ],
          ),
        ),
      ],
    );
  }

  /// build 1 button which calls Numbad controller handler
  Widget _buildNumpadButton(BuildContext context, NumpadController controller,
      String label, int value) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: TextButton(
          onPressed: () {
            // call interface method from controller
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
