import 'package:dart/styles.dart';
import 'package:flutter/material.dart';

class CricketBoard extends StatelessWidget {
  const CricketBoard({
    super.key,
    required this.hits,
  });

  final Map<int, int> hits;

  @override
  Widget build(BuildContext context) {
    final numbers = [15, 16, 17, 18, 19, 20, 25];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        String numberStr = number == 25 ? 'Bull' : number.toString();
        String circles = '';
        for (int i = 0; i < 3; i++) {
          circles += i < hits[number]! ? '●' : '○';
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                numberStr.padRight(4),
                style: checkNumberStyle(context),
              ),
              Text(
                circles,
                style: checkNumberStyle(context).copyWith(color: Colors.white),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
