import 'package:flutter/material.dart';

/// Interface for NumpadButton
abstract class NumpadController {
  void pressNumpadButton(BuildContext context, int value);
  String getInput();
  void correctDarts(int value);
}
