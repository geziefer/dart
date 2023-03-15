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
    String checkSymbol = currentNumber > number ? " ✅" : " ❌";
    // exclude numbers > 20
    if (number > 20) {
      return const Text('');
    } else {
      return Text(
        '$number:$checkSymbol  ',
        style: const TextStyle(
          fontSize: 70,
          color: Color.fromARGB(255, 215, 198, 132),
        ),
      );
    }
  }
}
