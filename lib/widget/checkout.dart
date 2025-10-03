import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:duration_button/duration_button.dart';
import 'package:flutter/material.dart';

class Checkout extends StatelessWidget {
  const Checkout({
    super.key,
    required this.remaining,
    required this.controller,
    required this.score,
    this.onClosed,
    this.isCheckoutMode = true,
  });

  final int remaining;
  final NumpadController controller;
  final int score;
  final VoidCallback? onClosed;
  final bool
      isCheckoutMode; // true for score-based checkout (default), false for target-based mode

  /// Determines the maximum number of darts possible for a given score
  /// Returns -1 for numbers out of range - Note: no bogey number check, will be done in controller
  int getMaxDartsForScore(int score) {
    if (score < 2 || score > 170) {
      return -1; // Not finishable with 1-3 darts
    }

    // 1 dart finishes: even numbers 2-40 and 50
    if ((score >= 2 && score <= 40 && score % 2 == 0) || score == 50) {
      return 1;
    }

    // 2 dart finishes: odd numbers 3-41, numbers 42-98, 100, 101, 104, 107, 110
    if ((score >= 3 && score <= 41 && score % 2 == 1) ||
        (score >= 42 && score <= 98) ||
        score == 100 ||
        score == 101 ||
        score == 104 ||
        score == 107 ||
        score == 110) {
      return 2;
    }

    // 3 dart finishes: 99, 102, 103, 105, 106, 108, 109 and all others except bogey numbers
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    int maxDarts;

    if (isCheckoutMode) {
      // Calculate the maximum darts for the score that was just thrown (original behavior)
      maxDarts = getMaxDartsForScore(score);

      if (remaining > 0 || maxDarts == -1) {
        return SizedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: Text(
                  "Maximale Dart-Anzahl erreicht",
                  style: endSummaryHeaderTextStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                child: DurationButton(
                  duration: const Duration(seconds: 3),
                  onPressed: () {
                    Navigator.pop(context);
                    onClosed?.call();
                  },
                  coverColor: Colors.black,
                  backgroundColor: Colors.grey[800],
                  width: 150,
                  height: 80,
                  child: Center(
                    child: Text(
                      'OK',
                      style: okButtonTextStyle(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Target mode: maximum darts is always 3, but minimum is the number of remaining targets
      maxDarts = 3;
    }

    // here we are if finish happened and was possible with 1 to 3 darts (checkout mode)
    // or if we have remaining targets (target mode)
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final dialogWidth = isPhone ? 300.0 : 550.0; // Much smaller width on phones
    final dialogHeight =
        isPhone ? 150.0 : 250.0; // Much smaller height on phones
    final buttonMargin = isPhone ? 5.0 : 10.0; // Smaller margins on phones

    return SizedBox(
      height: dialogHeight,
      width: dialogWidth,
      child: Column(
        children: [
          Text(
            "Wie viele Darts zum Finish?",
            style: endSummaryHeaderTextStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1 dart button - only show if remaining is exactly 1
                if ((isCheckoutMode && maxDarts == 1) ||
                    (!isCheckoutMode && remaining == 1))
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.all(buttonMargin),
                      child: TextButton(
                        onPressed: () {
                          // correct previously counted 3 darts to 1
                          controller.correctDarts(2);
                          Navigator.pop(context);
                          onClosed?.call();
                        },
                        style: finishButtonStyle(context),
                        child: Text(
                          "1",
                          style: finishButtonTextStyle(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                // 2 dart button - show if remaining is 1 or 2
                if ((isCheckoutMode && maxDarts <= 2) ||
                    (!isCheckoutMode && (remaining == 1 || remaining == 2)))
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.all(buttonMargin),
                      child: TextButton(
                        onPressed: () {
                          // correct previously counted 3 darts to 2
                          controller.correctDarts(1);
                          Navigator.pop(context);
                          onClosed?.call();
                        },
                        style: finishButtonStyle(context),
                        child: Text(
                          "2",
                          style: finishButtonTextStyle(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                // 3 dart button - always show
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.all(buttonMargin),
                    child: TextButton(
                      onPressed: () {
                        // nothing to correct, but call for update
                        controller.correctDarts(0);
                        Navigator.pop(context);
                        onClosed?.call();
                      },
                      style: finishButtonStyle(context),
                      child: Text(
                        "3",
                        style: finishButtonTextStyle(context),
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
