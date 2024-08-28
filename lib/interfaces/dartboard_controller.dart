import 'package:flutter/material.dart';

/// Interface for Dartboard taps
abstract class DartboardController {
  void pressDartboard(BuildContext context, String value);
}
