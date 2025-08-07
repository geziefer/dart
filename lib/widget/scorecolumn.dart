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

  bool _containsEmoji(String text) {
    return text.contains('✅') || text.contains('❌');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: scoreLabelTextStyle(context),
        ),
        Text(
          content,
          style: _containsEmoji(content) 
              ? emojiLargeTextStyle(context).copyWith(color: color)
              : scoreTextStyle(context).copyWith(color: color),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
