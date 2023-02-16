import 'dart:ui';

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
          style: const TextStyle(
            fontSize: 70,
            color: Color.fromARGB(255, 215, 198, 132),
          ),
        ),
        Text(
          content,
          style: TextStyle(
            fontSize: 70,
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
