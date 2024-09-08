import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/view/view_catchxx.dart';
import 'package:dart/view/view_finishes.dart';
import 'package:dart/view/view_halfit.dart';
import 'package:dart/view/view_rtcx.dart';
import 'package:dart/view/view_shootx.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Menu extends StatelessWidget {
  const Menu({
    super.key,
  });

  // MenuItems appear as plain list here, but will be displayed 4x5
  static final List<MenuItem> games = [
    MenuItem(
      id: '170m3',
      name: '170 x 10\nmax 3',
      view: const ViewXXXCheckout(title: '170 x 10 in 3 Aufnahmen'),
      controller: ControllerXXXCheckout(),
      params: const {'xxx': 170, 'max': 3, 'end': 10},
    ),
    MenuItem(
      id: '501x5',
      name: '501 x 5',
      view: const ViewXXXCheckout(title: '501 x 5 regulär'),
      controller: ControllerXXXCheckout(),
      params: const {'xxx': 501, 'max': -1, 'end': 5},
    ),
    MenuItem(
      id: '501m7',
      name: '501 x 5\nmax 7',
      view: const ViewXXXCheckout(title: '501 x 5 in 7 Aufnahmen'),
      controller: ControllerXXXCheckout(),
      params: const {'xxx': 501, 'max': 7, 'end': 5},
    ),
    MenuItem(
      id: 'FQ1',
      name: 'FinishQuest\n61-82',
      view: const ViewFinishes(title: 'Finishes wissen 61-82'),
      controller: ControllerFinishes(),
      params: const {'from': 61, 'to': 82},
    ),
    MenuItem(
      id: 'RTCS',
      name: 'RTC Single\nmax 10',
      view: const ViewRTCX(title: 'Round the Clock Single in 10 Aufnahmen'),
      controller: ControllerRTCX(),
      params: const {'max': 10},
    ),
    MenuItem(
      id: 'RTCD',
      name: 'RTC Double\nmax 20',
      view: const ViewRTCX(title: 'Round the Clock Double in 20 Aufnahmen'),
      controller: ControllerRTCX(),
      params: const {'max': 20},
    ),
    MenuItem(
      id: 'RTCT',
      name: 'RTC Triple\nmax 20',
      view: const ViewRTCX(title: 'Round the Clock Triple in 20 Aufnahmen'),
      controller: ControllerRTCX(),
      params: const {'max': 20},
    ),
    MenuItem(
      id: 'FQ2',
      name: 'FinishQuest\n83-104',
      view: const ViewFinishes(title: 'Finishes wissen 63-104'),
      controller: ControllerFinishes(),
      params: const {'from': 83, 'to': 104},
    ),
    MenuItem(
      id: 'C40',
      name: 'Catch 40',
      view: const ViewCatchXX(title: 'Catch 40 - Finish 61-100'),
      controller: ControllerCatchXX(),
      params: const {},
    ),
    MenuItem(
      id: 'F41',
      name: 'Finish 41',
      view: const ViewCatchXX(title: 'Finish 41 in 1 Aufnahme'),
      controller: ControllerCatchXX(),
      params: const {},
    ),
    MenuItem(
      id: 'C121',
      name: 'Check 121',
      view: const ViewCatchXX(title: 'Check 121 in 3 Aufnahmen mit Safepoint'),
      controller: ControllerCatchXX(),
      params: const {},
    ),
    MenuItem(
      id: 'FQ3',
      name: 'FinishQuest\n105-126',
      view: const ViewFinishes(title: 'Finishes wissen 105-126'),
      controller: ControllerFinishes(),
      params: const {'from': 105, 'to': 126},
    ),
    MenuItem(
      id: 'B27',
      name: 'Bob\'s 27',
      view: const ViewCatchXX(title: 'Bob\'s 27 - Double Round the Clock'),
      controller: ControllerCatchXX(),
      params: const {},
    ),
    MenuItem(
      id: 'D132',
      name: 'Double 132',
      view: const ViewCatchXX(title: 'Double 132 - Scoring mit Doubles'),
      controller: ControllerCatchXX(),
      params: const {},
    ),
    MenuItem(
      id: 'KB',
      name: 'Kill Bull',
      view: const ViewShootx(title: 'Kill Bull - Bull ohne Unterbrechung'),
      controller: ControllerShootx(),
      params: const {},
    ),
    MenuItem(
      id: 'FQ4',
      name: 'FinishQuest\n127-170',
      view: const ViewFinishes(title: 'Finishes wissen 127-170'),
      controller: ControllerFinishes(),
      params: const {'from': 127, 'to': 170},
    ),
    MenuItem(
      id: 'HI',
      name: 'Half it',
      view: const ViewHalfit(title: 'Half it'),
      controller: ControllerHalfit(),
      params: const {'max': -1},
    ),
    MenuItem(
      id: '99x20',
      name: '99 x 20',
      view: const ViewShootx(title: '99 x auf 20 scoren'),
      controller: ControllerShootx(),
      params: const {'x': 20, 'max': 33},
    ),
    MenuItem(
      id: '2D',
      name: '2 Darts',
      view: const ViewCatchXX(title: '2 Darts Finishes'),
      controller: ControllerCatchXX(),
      params: const {},
    ),
    MenuItem(
      id: 'NB',
      name: 'No Bogeys',
      view: const ViewFinishes(title: 'Bogey-Zahlen vermeiden'),
      controller: ControllerFinishes(),
      params: const {'from': 61, 'to': 170},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Image image =
        Image.asset('assets/images/logo.png', width: 500, fit: BoxFit.fitWidth);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Center(
        child: Column(
          children: [
            image,
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i <= 3; i++) games.elementAt(i),
                  ]),
            ),
            Expanded(
              flex: 1,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 4; i <= 7; i++) games.elementAt(i),
                  ]),
            ),
            Expanded(
              flex: 1,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 8; i <= 11; i++) games.elementAt(i),
                  ]),
            ),
            Expanded(
              flex: 1,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 12; i <= 15; i++) games.elementAt(i),
                  ]),
            ),
            Expanded(
              flex: 1,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 16; i <= 19; i++) games.elementAt(i),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.id,
    required this.name,
    required this.view,
    required this.controller,
    required this.params,
  });

  final String id;
  final String name;
  final Widget view;
  final MenuitemController controller;
  final Map params;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: OutlinedButton(
          onPressed: () {
            controller.init(this);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => view),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(width: 1.0, color: Colors.white),
            shape: const BeveledRectangleBorder(),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontSize: 42, color: Color.fromARGB(255, 215, 198, 132)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
