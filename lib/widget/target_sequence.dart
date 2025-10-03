import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
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
    final isPhone = ResponsiveUtils.isPhoneSize(context);
    final spacing = isPhone ? 1.0 : 8.0;
    final aspectRatio = isPhone ? 3.0 : 2.0;
    final containerMargin = isPhone ? 2.0 : 8.0;
    
    return Container(
      margin: EdgeInsets.all(containerMargin),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
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
