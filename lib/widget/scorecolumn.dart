import 'package:dart/styles.dart';
import 'package:flutter/material.dart';

class ScoreColumn extends StatelessWidget {
  const ScoreColumn({
    super.key,
    required this.label,
    required this.content,
    required this.color,
  });

  final String label;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: scoreLabelTextStyle,
        ),
        Text(
          content,
          style: TextStyle(
            fontSize: 68,
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
            color: color,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
