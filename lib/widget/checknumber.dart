import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:flutter/material.dart';

class CheckNumber extends StatelessWidget {
  const CheckNumber({
    super.key,
    required this.currentNumber,
    required this.number,
    this.result, // null = use currentNumber logic; true = ✅; false = ❌
  });

  final int currentNumber;
  final int number;
  /// Explicit result for Scolia challenge mode. When null, falls back to
  /// the standard "currentNumber > number" check.
  final bool? result;

  @override
  Widget build(BuildContext context) {
    bool showCheck;
    bool showCross = false;
    if (result != null) {
      showCheck = result!;
      showCross = !result!;
    } else {
      showCheck = currentNumber > number;
    }
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final numberWidth = isPhone ? 60.0 : 100.0;
    final checkWidth = isPhone ? 60.0 : 110.0;

    // exclude numbers > 20 — render a blank cell of the SAME height as a real
    // row so the 3-column grid stays a uniform rectangle (the 21st cell is
    // empty because there are only 20 numbers). A zero-height cell would make
    // the last column shorter and misalign it.
    if (number > 20) {
      return Row(
        children: [
          SizedBox(
            width: numberWidth,
            child: Text('\u{00A0}', style: checkNumberStyle(context)),
          ),
          SizedBox(
            width: checkWidth,
            child: Text('\u{00A0}', style: checkNumberStyle(context)),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          SizedBox(
            width: numberWidth,
            child: Text(
              '$number:',
              style: checkNumberStyle(context),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: checkWidth,
            child: Row(
              children: [
                if (showCheck)
                  Text('✅', style: emojiTextStyle(context))
                else if (showCross)
                  Text('❌', style: emojiTextStyle(context))
                else
                  Text('\u{00A0}', style: checkNumberStyle(context)),
                Text('', style: checkNumberStyle(context)),
              ],
            ),
          ),
        ],
      );
    }
  }
}
