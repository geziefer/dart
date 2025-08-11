import 'package:flutter/material.dart';
import 'package:dart/utils/responsive.dart';

// Button styles that need responsive sizing
ButtonStyle headerButtonStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
  // Make button larger on phones to ensure arrow is fully visible
  final phoneScale = ResponsiveUtils.isPhoneSize(context) ? 1.2 : 1.0;
  return OutlinedButton.styleFrom(
    side: const BorderSide(width: 3.0, color: Colors.white),
    minimumSize: Size(50 * scaleFactor * phoneScale, 80 * scaleFactor * phoneScale),
    padding: EdgeInsets.all(8 * scaleFactor), // Add padding for better icon visibility
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
    alignment: Alignment.center, // Ensure text is centered vertically
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

ButtonStyle finishButtonStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
  // Make buttons much smaller on phones to reduce dialog size
  final phoneScale = ResponsiveUtils.isPhoneSize(context) ? 0.5 : 1.0; // Reduced from 0.7 to 0.5
  return TextButton.styleFrom(
    backgroundColor: Colors.black,
    minimumSize: Size(60 * scaleFactor * phoneScale, 50 * scaleFactor * phoneScale), // Reduced base sizes
    padding: EdgeInsets.all(4 * scaleFactor * phoneScale), // Reduced padding
    shape: const BeveledRectangleBorder(),
  );
}

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
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.85  // Increased from 0.75 for better readability
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
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.85  // Increased from 0.75 for better readability
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    fontSize: 60 * scaleFactor, // Reduced from 68 to 60 for better 5-line fit
    height: 1.1, // Tighter line spacing (default is ~1.2)
    color: const Color.fromARGB(255, 215, 198, 132),
  );
}

TextStyle scoreTextStyle(BuildContext context) {
  final scaleFactor = ResponsiveUtils.isPhoneSize(context) 
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.85  // Increased from 0.75 for better readability
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    fontSize: 60 * scaleFactor, // Reduced from 68 to 60 for better 5-line fit
    height: 1.1, // Tighter line spacing (default is ~1.2)
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
  // Use same scaling as checkNumberStyle for consistent alignment in RTCX
  final scaleFactor = ResponsiveUtils.isPhoneSize(context) 
      ? ResponsiveUtils.getTextScaleFactor(context) * 0.85  // Updated to match checkNumberStyle
      : ResponsiveUtils.getTextScaleFactor(context);
  return TextStyle(
    fontSize: 50 * scaleFactor, // Match checkNumberStyle font size
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
