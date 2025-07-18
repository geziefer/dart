import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_killbull.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // initialize all local data storages with id as key
  for (var box in Menu.games) {
    await GetStorage.init(box.id);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ControllerXXXCheckout()),
        ChangeNotifierProvider(create: (context) => ControllerRTCX()),
        ChangeNotifierProvider(create: (context) => ControllerHalfit()),
        ChangeNotifierProvider(create: (context) => ControllerFinishes()),
        ChangeNotifierProvider(create: (context) => ControllerShootx()),
        ChangeNotifierProvider(create: (context) => ControllerCatchXX()),
        ChangeNotifierProvider(create: (context) => ControllerKillBull()),
      ],
      child: const MaterialApp(
        title: 'DART - Damit Alex Richtig Trainiert',
        home: Menu(),
      ),
    ),
  );
}
