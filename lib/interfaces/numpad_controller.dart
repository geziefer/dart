/// Interface for NumpadButton
abstract class NumpadController {
  void pressNumpadButton(int value);
  String getInput();
  void correctDarts(int value);
  bool isButtonDisabled(int value) => false; // default implementation
}
