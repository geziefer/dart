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
import 'package:dart/controller/controller_bigts.dart';
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
import 'package:dart/view/view_bigts.dart';
import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:dart/widget/version_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      getController: (context) =>
          Provider.of<ControllerXXXCheckout>(context, listen: false),
      params: const {'xxx': 170, 'max': 3, 'end': 10},
    ),
    MenuItem(
      id: 'BigTs',
      name: 'Big Ts',
      view: const ViewBigTs(title: 'Big Ts - T20, T19, T18'),
      getController: (context) =>
          Provider.of<ControllerBigTs>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: '501m7',
      name: '501 x 5\nmax 7',
      view: const ViewXXXCheckout(title: '501 x 5 in 7 Aufnahmen'),
      getController: (context) =>
          Provider.of<ControllerXXXCheckout>(context, listen: false),
      params: const {'xxx': 501, 'max': 7, 'end': 5},
    ),
    MenuItem(
      id: 'FQ1',
      name: 'FinishQuest\n61-80',
      view: const ViewFinishes(title: 'Finishes wissen 61-80'),
      getController: (context) =>
          Provider.of<ControllerFinishes>(context, listen: false),
      params: const {'from': 61, 'to': 80},
    ),
    MenuItem(
      id: 'RTCS',
      name: 'RTC Single\nmax 10',
      view: const ViewRTCX(title: 'Round the Clock Single'),
      getController: (context) =>
          Provider.of<ControllerRTCX>(context, listen: false),
      params: const {'max': 10},
    ),
    MenuItem(
      id: 'RTCD',
      name: 'RTC Double\nmax 20',
      view: const ViewRTCX(title: 'Round the Clock Double'),
      getController: (context) =>
          Provider.of<ControllerRTCX>(context, listen: false),
      params: const {'max': 20},
    ),
    MenuItem(
      id: 'RTCT',
      name: 'RTC Triple\nmax 20',
      view: const ViewRTCX(title: 'Round the Clock Triple'),
      getController: (context) =>
          Provider.of<ControllerRTCX>(context, listen: false),
      params: const {'max': 20},
    ),
    MenuItem(
      id: 'FQ2',
      name: 'FinishQuest\n81-107',
      view: const ViewFinishes(title: 'Finishes wissen 81-107'),
      getController: (context) =>
          Provider.of<ControllerFinishes>(context, listen: false),
      params: const {'from': 81, 'to': 107},
    ),
    MenuItem(
      id: 'C40',
      name: 'Catch 40',
      view: const ViewCatchXX(title: 'Catch 40 - Finish 61-100'),
      getController: (context) =>
          Provider.of<ControllerCatchXX>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: '10U1D',
      name: '10 Up\n1 Down',
      view: const ViewUpDown(title: '10 Up 1 Down - Finish ab 50'),
      getController: (context) =>
          Provider.of<ControllerUpDown>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: 'C121',
      name: 'Check 121',
      view: const ViewCheck121(title: 'Check 121 - 3 Aufnahmen + Safepoint'),
      getController: (context) =>
          Provider.of<ControllerCheck121>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: 'FQ3',
      name: 'FinishQuest\n108-135',
      view: const ViewFinishes(title: 'Finishes wissen 108-135'),
      getController: (context) =>
          Provider.of<ControllerFinishes>(context, listen: false),
      params: const {'from': 108, 'to': 135},
    ),
    MenuItem(
      id: 'B27',
      name: 'Bob\'s 27',
      view: const ViewBobs27(title: 'Bob\'s 27 - Double Round the Clock'),
      getController: (context) =>
          Provider.of<ControllerBobs27>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: 'DPath',
      name: 'Double Path',
      view: const ViewDoublePath(title: 'Double Path - Typische Double Pfade'),
      getController: (context) =>
          Provider.of<ControllerDoublePath>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: 'KB',
      name: 'Kill Bull',
      view: const ViewKillBull(title: 'Kill Bull - Bull ohne Unterbrechung'),
      getController: (context) =>
          Provider.of<ControllerKillBull>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: 'FQ4',
      name: 'FinishQuest\n136-170',
      view: const ViewFinishes(title: 'Finishes wissen 136-170'),
      getController: (context) =>
          Provider.of<ControllerFinishes>(context, listen: false),
      params: const {'from': 136, 'to': 170},
    ),
    MenuItem(
      id: 'HI',
      name: 'Half it',
      view: const ViewHalfit(title: 'Half it'),
      getController: (context) =>
          Provider.of<ControllerHalfit>(context, listen: false),
      params: const {'max': -1},
    ),
    MenuItem(
      id: '99x20',
      name: '99 x 20',
      view: const ViewShootx(title: '99 x auf 20 scoren'),
      getController: (context) =>
          Provider.of<ControllerShootx>(context, listen: false),
      params: const {'x': 20, 'max': 33},
    ),
    MenuItem(
      id: '2D',
      name: '2 Darts',
      view: const ViewTwoDarts(title: '2 Darts - Finishes 61-70 mit Bull'),
      getController: (context) =>
          Provider.of<ControllerTwoDarts>(context, listen: false),
      params: const {},
    ),
    MenuItem(
      id: 'SB',
      name: 'Speed Bull',
      view: const ViewSpeedBull(title: 'Speed Bull - 1 Minute Bulls'),
      getController: (context) =>
          Provider.of<ControllerSpeedBull>(context, listen: false),
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
            // Header with version info
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const VersionInfo(),
                ],
              ),
            ),
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
    required this.getController,
    required this.params,
  });

  final String id;
  final String name;
  final Widget view;
  final MenuitemController Function(BuildContext) getController;
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
          // Initialize the controller from Provider before navigation to ensure fresh game state
          final controller = menuItem.getController(context);
          controller.init(menuItem);

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
              ResponsiveUtils.isPhoneSize(context)
                  ? menuItem.name.replaceAll('\n', ' ') // Single line on phones
                  : menuItem.name, // Keep newlines on tablets
              style: menuButtonTextStyle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
