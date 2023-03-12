import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ControllerXXXCheckout()),
      ],
      child: const MaterialApp(
        title: 'DART - Damit Alex Richtig Trainiert',
        home: Menu(),
      ),
    ),
  );
}
