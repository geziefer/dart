import 'package:dart/styles.dart';
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
    String checkSymbol = currentNumber > number ? " ✅" : "\u{00A0}";
    // exclude numbers > 20
    if (number > 20) {
      return const Text('');
    } else {
      return Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$number:',
              style: checkNumberStyle,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '$checkSymbol  ',
              style: checkNumberStyle,
            ),
          ),
        ],
      );
    }
  }
}
