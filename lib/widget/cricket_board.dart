import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
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
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final verticalPadding = isPhone ? 0.2 : 2.0;
    final circleSize = isPhone ? 35.0 : 60.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        String numberStr = number == 25 ? 'B' : number.toString();

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  numberStr,
                  style: checkNumberStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: circleSize,
                    height: circleSize,
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
