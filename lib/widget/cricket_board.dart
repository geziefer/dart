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
        String numberStr = number == 25 ? 'B' : number.toString();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                numberStr.padRight(4),
                style: checkNumberStyle(context),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      i < hits[number]! ? '●' : '◯',
                      style: checkNumberStyle(context).copyWith(
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
