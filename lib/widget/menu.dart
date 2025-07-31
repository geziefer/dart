import 'package:dart/controller/controller_catchxx.dart';
import 'package:dart/controller/controller_finishes.dart';
import 'package:dart/controller/controller_halfit.dart';
import 'package:dart/controller/controller_killbull.dart';
import 'package:dart/controller/controller_rtcx.dart';
import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/controller/controller_shootx.dart';
import 'package:dart/controller/controller_bobs27.dart';
import 'package:dart/controller/controller_twodarts.dart';
import 'package:dart/controller/controller_check121.dart';
import 'package:dart/controller/controller_speedbull.dart';
import 'package:dart/controller/controller_doublepath.dart';
import 'package:dart/controller/controller_updown.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/view/view_catchxx.dart';
import 'package:dart/view/view_finishes.dart';
import 'package:dart/view/view_halfit.dart';
import 'package:dart/view/view_killbull.dart';
import 'package:dart/view/view_rtcx.dart';
import 'package:dart/view/view_shootx.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:dart/view/view_bobs27.dart';
import 'package:dart/view/view_twodarts.dart';
import 'package:dart/view/view_check121.dart';
import 'package:dart/view/view_speedbull.dart';
import 'package:dart/view/view_doublepath.dart';
import 'package:dart/view/view_updown.dart';
import 'package:dart/styles.dart';
import 'package:flutter/material.dart';

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
      id: '10U1D',
      name: '10 Up\n1 Down',
      view: const ViewUpDown(title: '10 Up 1 Down - Finish ab 50'),
      controller: ControllerUpDown(),
      params: const {},
    ),
    MenuItem(
      id: 'C121',
      name: 'Check 121',
      view: const ViewCheck121(title: 'Check 121 in 3 Aufnahmen mit Safepoint'),
      controller: ControllerCheck121(),
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
      view: const ViewBobs27(title: 'Bob\'s 27 - Double Round the Clock'),
      controller: ControllerBobs27(),
      params: const {},
    ),
    MenuItem(
      id: 'DPath',
      name: 'Double Path',
      view: const ViewDoublePath(title: 'Double Path - Typische Double Pfade'),
      controller: ControllerDoublePath(),
      params: const {},
    ),
    MenuItem(
      id: 'KB',
      name: 'Kill Bull',
      view: const ViewKillBull(title: 'Kill Bull - Bull ohne Unterbrechung'),
      controller: ControllerKillBull.create(),
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
      view:
          const ViewTwoDarts(title: '2 Darts - Finishes 61-70 mit Double Bull'),
      controller: ControllerTwoDarts(),
      params: const {},
    ),
    MenuItem(
      id: 'SB',
      name: 'Speed Bull',
      view: const ViewSpeedBull(title: 'Speed Bull - 1 Minute Bulls'),
      controller: ControllerSpeedBull(),
      params: const {'duration': 60},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Image image =
        Image.asset('assets/images/logo.png', width: 500, fit: BoxFit.fitWidth);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Center(
        child: Column(
          children: [
            image,
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the available height for the grid
                  final availableHeight =
                      constraints.maxHeight - 16; // subtract padding
                  final availableWidth =
                      constraints.maxWidth - 16; // subtract padding

                  // Calculate aspect ratio based on available space
                  // 5 rows, 4 columns, with spacing
                  final itemHeight =
                      (availableHeight - (4 * 8)) / 5; // 4 gaps between 5 rows
                  final itemWidth = (availableWidth - (3 * 8)) /
                      4; // 3 gaps between 4 columns
                  final calculatedAspectRatio = itemWidth / itemHeight;

                  return GridView.count(
                    crossAxisCount: 4,
                    childAspectRatio: calculatedAspectRatio,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    padding: const EdgeInsets.all(8),
                    physics: const NeverScrollableScrollPhysics(),
                    children: games
                        .map((game) => MenuItemButton(menuItem: game))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem {
  const MenuItem({
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
  final Map<String, dynamic> params;
}

class MenuItemButton extends StatelessWidget {
  const MenuItemButton({
    super.key,
    required this.menuItem,
  });

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => menuItem.view,
              settings: RouteSettings(arguments: menuItem),
            ),
          );
        },
        style: menuButtonStyle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              menuItem.name,
              style: menuButtonTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
