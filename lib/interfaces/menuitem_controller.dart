import 'package:dart/widget/menu.dart';

/// Interface for Controller in menu, receives its item
abstract class MenuitemController {
  void init(MenuItem item);
  
  /// Initialize the controller instance with the menu item
  void initFromProvider(MenuItem item);
}
