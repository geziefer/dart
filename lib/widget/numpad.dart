import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:flutter/material.dart';

/// Build 4x3 numpad 0-9, undo, return, possibly extra buttons or yes/no
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.controller,
    required this.showUpper,
    required this.showMiddle,
    required this.showLower,
    required this.showExtraButtons,
    required this.showYesNo,
    this.cricketMode = false,
  });

  // Convenience constructor for Plan Hit game (only 0-3 buttons)
  const Numpad.planHit({
    super.key,
    required this.controller,
  }) : showUpper = false,
       showMiddle = false,
       showLower = true,
       showExtraButtons = false,
       showYesNo = false,
       cricketMode = false;

  final NumpadController controller; // controller class which supports Numpad
  final bool showUpper; // flag if upper row 7-9 should be shown
  final bool showMiddle; // flag if middle row 4-6 should be shown
  final bool showLower; // flag if lower row 1-3 should be shown
  final bool
      showExtraButtons; // flag if extra buttons for predefined results should be shown
  final bool showYesNo; // flag if only yes and no should be shown in lower row
  final bool cricketMode; // flag if cricket mode is active (changes button labels)

  @override
  Widget build(BuildContext context) {
    // Define button labels and values based on mode
    final List<String> labels = cricketMode 
        ? ['15', '16', '17', '18', '19', '20', '', 'B', '']
        : ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    final List<int> values = cricketMode 
        ? [15, 16, 17, 18, 19, 20, -99, 25, -99]  // -99 for disabled, 25 for Bull
        : [1, 2, 3, 4, 5, 6, 7, 8, 9];

    return Row(
      children: [
        if (showExtraButtons && !cricketMode)
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
                      style: numpadInputTextStyle(context),
                    ),
                    const Divider(color: Colors.white, thickness: 3),
                  ],
                ),
              ),
              if (showUpper)
                Expanded(
                  flex: 1,
                  // ########## 1st row 7, 8, 9 (or disabled, B, disabled in cricket)
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 6; i <= 8; i++)  // indices 6,7,8 for buttons 7,8,9
                        _buildNumpadButton(
                            context, controller, labels[i], values[i], true),
                    ],
                  ),
                ),
              if (showMiddle)
                Expanded(
                  flex: 1,
                  // ########## 2nd row 4, 5, 6 (or 18, 19, 20 in cricket)
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 3; i <= 5; i++)  // indices 3,4,5 for buttons 4,5,6
                        _buildNumpadButton(
                            context, controller, labels[i], values[i], true),
                    ],
                  ),
                ),
              if (showLower)
                Expanded(
                  flex: 1,
                  // ########## 3rd row 1, 2, 3 (or 15, 16, 17 in cricket)
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i <= 2; i++)  // indices 0,1,2 for buttons 1,2,3
                        _buildNumpadButton(
                            context, controller, labels[i], values[i], true),
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
    bool isDisabled = controller.isButtonDisabled(value);
    bool isEmoji = label == '❌' || label == '✅';

    // Use smaller margins on phone screens to save space
    final buttonMargin = ResponsiveUtils.getButtonMargin(context);

    return Expanded(
      flex: 1,
      child: Container(
        margin: EdgeInsets.all(buttonMargin),
        child: TextButton(
          onPressed: isDisabled
              ? null
              : () => controller.pressNumpadButton(value),
          onLongPress: isDisabled
              ? null
              : () {
                  if (value == -1) {
                    controller.pressNumpadButton(-3);
                  }
                },
          style: isDisabled 
              ? numpadDisabledTextStyle 
              : numpadTextStyle.copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.grey[300];
                    }
                    return null;
                  }),
                ),
          child: Text(
            label,
            style: isEmoji
                ? emojiTextStyle(context)
                : isDisabled
                    ? (large
                        ? numpadScoreButtonLargeDisabledTextStyle(context)
                        : numpadScoreButtonSmallDisabledTextStyle(context))
                    : (large
                        ? numpadScoreButtonLargeTextStyle(context)
                        : numpadScoreButtonSmallTextStyle(context)),
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
