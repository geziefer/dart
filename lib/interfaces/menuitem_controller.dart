import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';

/// Interface for Controller in menu, receives its item
abstract class MenuitemController {
  void init(MenuItem item);
  
  /// Initialize the Provider controller instance with the menu item
  void initFromProvider(BuildContext context, MenuItem item);
}
