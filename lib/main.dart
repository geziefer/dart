import 'package:dart/controller/controller_bulls.dart';
import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_rtcx.dart';
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
        ChangeNotifierProvider(create: (context) => ControllerRTCX()),
        ChangeNotifierProvider(create: (context) => ControllerHalfit()),
        ChangeNotifierProvider(create: (context) => ControllerFinishes()),
        ChangeNotifierProvider(create: (context) => ControllerBulls()),
        ChangeNotifierProvider(create: (context) => ControllerCatchXX()),
      ],
      child: const MaterialApp(
        title: 'DART - Damit Alex Richtig Trainiert',
        home: Menu(),
      ),
    ),
  );
}
