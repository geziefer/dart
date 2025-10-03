import 'package:dart/styles.dart';
import 'package:flutter/material.dart';

class TargetSequence extends StatelessWidget {
  const TargetSequence({
    super.key,
    required this.targets,
    required this.targetsHit,
    required this.currentTargetIndex,
  });

  final List<String> targets;
  final List<bool> targetsHit;
  final int currentTargetIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: targets.length,
        itemBuilder: (context, index) {
          bool isHit = targetsHit[index];
          bool isCurrent = index == currentTargetIndex;
          
          Color textColor;
          if (isHit) {
            textColor = Colors.green;
          } else if (isCurrent) {
            textColor = Colors.yellow;
          } else {
            textColor = Colors.white;
          }
          
          return Center(
            child: Text(
              targets[index],
              style: checkNumberStyle(context).copyWith(
                color: textColor,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
