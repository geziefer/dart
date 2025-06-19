import 'package:dart/styles.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/material.dart';

/// Build 4x3 numpad 0-9, undo, return, possibly extra buttons or yes/no
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.controller,
    required this.showUpper,
    required this.showMiddle,
    required this.showExtraButtons,
    required this.showYesNo,
  });

  final NumpadController controller; // controller class which supports Numpad
  final bool showUpper; // flag if upper row 7-9 should be shown
  final bool showMiddle; // flag if middle row 4-6 should be shown
  final bool
      showExtraButtons; // flag if extra buttons for predefined results should be shown
  final bool showYesNo; // flag if only yes and no should be shown in lower row

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showExtraButtons)
          _buildExtraButtons(context, controller, showExtraButtons),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                flex: 1,
                // ########## input
                child: Column(
                  children: [
                    Text(
                      controller.getInput(),
                      style: numpadInputTextStyle,
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
                        _buildNumpadButton(
                            context, controller, i.toString(), i, true),
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
                        _buildNumpadButton(
                            context, controller, i.toString(), i, true),
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
                      _buildNumpadButton(
                          context, controller, i.toString(), i, true),
                  ],
                ),
              ),
              // ########## 4th row back, 0, enter or back, yes, no
              if (showYesNo)
                Expanded(
                  flex: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNumpadButton(context, controller, '↶', -2, true),
                      _buildNumpadButton(context, controller, '❌', 0, true),
                      _buildNumpadButton(context, controller, '✅', 1, true),
                    ],
                  ),
                )
              else
                Expanded(
                  flex: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNumpadButton(context, controller, '↶', -2, true),
                      _buildNumpadButton(context, controller, '0', 0, true),
                      _buildNumpadButton(context, controller, '↵', -1, true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// build 1 button which calls Numbad controller handler
  Widget _buildNumpadButton(BuildContext context, NumpadController controller,
      String label, int value, bool large) {
    double fontSize = large ? 50 : 36;
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(10),
        child: TextButton(
          onPressed: () {
            // call interface method from controller
            controller.pressNumpadButton(context, value);
          },
          // for enter button accept long press as rest value, other ignore
          onLongPress: () {
            if (value == -1) {
              controller.pressNumpadButton(context, -3);
            }
          },
          style: numpadTextStyle,
          child: Text(
            label,
            style: TextStyle(fontSize: fontSize, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// build extra buttons with predefined results
  Widget _buildExtraButtons(BuildContext context, NumpadController controller,
      bool showExtraButtons) {
    return Expanded(
      flex: 2,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNumpadButton(context, controller, '41', 41, false),
                _buildNumpadButton(context, controller, '45', 45, false),
                _buildNumpadButton(context, controller, '60', 60, false),
                _buildNumpadButton(context, controller, '83', 83, false),
                _buildNumpadButton(context, controller, '95', 95, false),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNumpadButton(context, controller, '43', 43, false),
                _buildNumpadButton(context, controller, '55', 55, false),
                _buildNumpadButton(context, controller, '81', 81, false),
                _buildNumpadButton(context, controller, '85', 85, false),
                _buildNumpadButton(context, controller, '100', 100, false),
              ],
            ),
          ),
          const VerticalDivider(color: Colors.white, thickness: 1),
        ],
      ),
    );
  }
}
