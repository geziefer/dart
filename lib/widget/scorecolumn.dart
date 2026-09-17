import 'package:dart/styles.dart';
import 'package:flutter/material.dart';

class ScoreColumn extends StatelessWidget {
  const ScoreColumn({
    super.key,
    required this.label,
    required this.content,
    required this.color,
    this.maxLines = 5,
  });

  final String label;
  final String content;
  final Color color;

  /// Number of content lines to reserve vertical space for. All game tables
  /// use a 5-line window (see `createMultilineString(..., 5, ...)`), so the
  /// block always reserves 5 lines. This keeps the table a stable height:
  /// content stays top-aligned and grows downward (as before), while the
  /// whole fixed-height block is centered vertically so the space freed by
  /// the smaller font is distributed evenly above and below it.
  final int maxLines;

  bool _containsEmoji(String text) {
    return text.contains('✅') || text.contains('❌');
  }

  /// Pad the content with trailing blank lines so the Text always occupies
  /// [maxLines] lines. The visible rows remain top-aligned and grow downward;
  /// the invisible trailing lines merely reserve the height.
  String _padToMaxLines(String text) {
    final lineCount = text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;
    if (lineCount >= maxLines) return text;
    return text + '\n' * (maxLines - lineCount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // Center the fixed-height block vertically; distribute freed space
      // evenly above and below (looks natural on taller screens like Pixel C).
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: scoreLabelTextStyle(context),
        ),
        Text(
          _padToMaxLines(content),
          maxLines: maxLines,
          style: _containsEmoji(content)
              ? emojiLargeTextStyle(context).copyWith(color: color)
              : scoreTextStyle(context).copyWith(color: color),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
