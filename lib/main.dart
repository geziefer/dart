import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_rtcdouble.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

void main() async {
  for (var box in Menu.games.keys) {
    await GetStorage.init(box.toString());
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ControllerXXXCheckout()),
        ChangeNotifierProvider(create: (context) => ControllerRTCDouble()),
        ChangeNotifierProvider(create: (context) => ControllerHalfit()),
      ],
      child: const MaterialApp(
        title: 'DART - Damit Alex Richtig Trainiert',
        home: Menu(),
      ),
    ),
  );
}
