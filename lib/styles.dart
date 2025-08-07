import 'package:flutter/material.dart';
import 'package:dart/utils/responsive.dart';

// Button styles that need responsive sizing
ButtonStyle headerButtonStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
  return OutlinedButton.styleFrom(
    side: const BorderSide(width: 3.0, color: Colors.white),
    minimumSize: Size(40 * scaleFactor, 70 * scaleFactor),
    shape: const CircleBorder(),
  );
}

TextStyle menuButtonTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 42 * ResponsiveUtils.getMenuButtonTextScale(context),
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

final menuButtonStyle = OutlinedButton.styleFrom(
  side: const BorderSide(width: 1.0, color: Colors.white),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
);

ButtonStyle okButtonStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
  return TextButton.styleFrom(
    backgroundColor: Colors.black,
    minimumSize: Size(150 * scaleFactor, 80 * scaleFactor),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2))),
  );
}

TextStyle okButtonTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 50),
    color: Colors.white,
  );
}

final finishButtonStyle = TextButton.styleFrom(
  backgroundColor: Colors.black,
  shape: const BeveledRectangleBorder(),
);

TextStyle finishButtonTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 50),
    color: Colors.white,
  );
}

TextStyle statsTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 50 * ResponsiveUtils.getStatsScale(context),
    color: Colors.white,
  );
}

TextStyle statsNumberTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 50 * ResponsiveUtils.getStatsScale(context),
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

TextStyle statsSummaryTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 40 * ResponsiveUtils.getStatsScale(context),
    color: Colors.white,
  );
}

TextStyle endSummaryHeaderTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 50),
    color: Colors.black,
  );
}

TextStyle endSummaryTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 32),
    color: Colors.black,
  );
}

TextStyle endSummaryEmphasizedTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 35),
    color: Colors.red,
  );
}

TextStyle checkNumberStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.isPhoneSize(context) 
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.75  // Increased from 0.6 to 0.75
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    fontSize: 50 * scaleFactor,
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

TextStyle numpadInputTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 70),
    color: Colors.white,
  );
}

TextStyle numpadScoreButtonLargeTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 50 * ResponsiveUtils.getNumpadLargeButtonScale(context),
    color: Colors.white,
  );
}

TextStyle numpadScoreButtonSmallTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 35 * ResponsiveUtils.getNumpadSmallButtonScale(context),
    color: Colors.white,
  );
}

final numpadTextStyle = TextButton.styleFrom(
  backgroundColor: Colors.white24,
  shape: const BeveledRectangleBorder(),
);

final numpadDisabledTextStyle = TextButton.styleFrom(
  backgroundColor: Colors.grey.withValues(alpha: 0.3),
  shape: const BeveledRectangleBorder(),
);

TextStyle numpadScoreButtonLargeDisabledTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 50 * ResponsiveUtils.getNumpadLargeButtonScale(context),
    color: Colors.grey,
  );
}

TextStyle numpadScoreButtonSmallDisabledTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 32 * ResponsiveUtils.getNumpadSmallButtonScale(context),
    color: Colors.grey,
  );
}

TextStyle scoreLabelTextStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.isPhoneSize(context) 
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.75  // Increased from 0.6 to 0.75
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    fontSize: 68 * scaleFactor,
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

TextStyle scoreTextStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.isPhoneSize(context) 
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.75  // Increased from 0.6 to 0.75
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    fontSize: 68 * scaleFactor,
    fontFeatures: const <FontFeature>[
      FontFeature.tabularFigures(),
    ],
    color: Colors.white,
  );
}

TextStyle boardTextStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.isPhoneSize(context) 
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.7  // Smaller for phone screens
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 30 * scaleFactor,
  );
}

TextStyle outputTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 45),
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

TextStyle inputTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 45),
    color: Colors.white,
  );
}

TextStyle emojiTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 45),
    fontFamily: "NotoColorEmoji",
  );
}

TextStyle timerTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 100),
    fontWeight: FontWeight.bold,
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

TextStyle emojiLargeTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 68),
    fontFamily: "NotoColorEmoji",
  );
}
