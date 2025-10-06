import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getTextScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use the smaller dimension to determine scale factor
    // This works for both landscape and portrait orientations
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;

    // Base dimension for tablet (assuming your app was designed for ~800px height in landscape)
    const baseTabletDimension = 800.0;

    // Calculate scale factor with more aggressive scaling for phones
    double scaleFactor = smallerDimension / baseTabletDimension;

    // More aggressive scaling for smaller screens
    if (smallerDimension < 500) {
      // Very small phones - scale down significantly
      scaleFactor = scaleFactor * 0.7; // Additional 30% reduction
    } else if (smallerDimension < 600) {
      // Regular phones - scale down moderately
      scaleFactor = scaleFactor * 0.8; // Additional 20% reduction
    }

    // Clamp the scale factor to reasonable bounds
    // Minimum 0.35 (for very small phones) and maximum 1.2 (for very large tablets)
    scaleFactor = scaleFactor.clamp(0.35, 1.2);

    return scaleFactor;
  }

  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    return baseFontSize * getTextScaleFactor(context);
  }

  static bool isPhoneSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;

    // Consider it a phone if the smaller dimension is less than 600px
    return smallerDimension < 600;
  }

  static double getCheckoutDialogTextScale(BuildContext context) {
    final baseScale = getTextScaleFactor(context);
    // Increase checkout dialog text size on small screens for better readability
    return isPhoneSize(context) ? baseScale * 1.4 : baseScale;
  }

  static double getHeaderTextScale(BuildContext context) {
    final baseScale = getTextScaleFactor(context);
    // Increase header text size by 50% on small screens for better visibility
    return isPhoneSize(context) ? baseScale * 1.5 : baseScale;
  }

  // Specific scaling for different UI elements based on your feedback
  static double getMenuButtonTextScale(BuildContext context) {
    final baseScale = getTextScaleFactor(context);
    // Menu buttons now use single line on phones, so can be larger
    return isPhoneSize(context) ? baseScale * 1.4 : baseScale;
  }

  static double getNumpadLargeButtonScale(BuildContext context) {
    final baseScale = getTextScaleFactor(context);
    // Increase scaling for better readability - there's space on buttons
    return isPhoneSize(context)
        ? baseScale * 1.3
        : baseScale; // Increased from 0.95
  }

  static double getNumpadSmallButtonScale(BuildContext context) {
    final baseScale = getTextScaleFactor(context);
    // Increase scaling for better readability - there's space on buttons
    return isPhoneSize(context)
        ? baseScale * 1.4
        : baseScale; // Increased from 1.2
  }

  static double getStatsScale(BuildContext context) {
    final baseScale = getTextScaleFactor(context);
    // Increase stats text size for better readability on small screens
    return isPhoneSize(context) ? baseScale * 1.2 : baseScale;
  }

  // Utility function for responsive margins
  static double getButtonMargin(BuildContext context) {
    return isPhoneSize(context) ? 3.0 : 10.0;
  }
}
