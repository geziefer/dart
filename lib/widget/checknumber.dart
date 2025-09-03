import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:flutter/material.dart';

class CheckNumber extends StatelessWidget {
  const CheckNumber({
    super.key,
    required this.currentNumber,
    required this.number,
  });

  final int currentNumber;
  final int number;

  @override
  Widget build(BuildContext context) {
    bool showCheck = currentNumber > number;
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final numberWidth = isPhone ? 60.0 : 100.0;
    final checkWidth = isPhone ? 60.0 : 110.0;

    // exclude numbers > 20
    if (number > 20) {
      return const Text('');
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
                  Text(
                    '✅',
                    style: emojiTextStyle(context),
                  )
                else
                  Text(
                    '\u{00A0}', // non-breaking space
                    style: checkNumberStyle(context),
                  ),
                Text('', style: checkNumberStyle(context)), // reduced spacing
              ],
            ),
          ),
        ],
      );
    }
  }
}
