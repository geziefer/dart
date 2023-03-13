import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Menu extends StatelessWidget {
  const Menu({
    super.key,
  });

  static final Map games = {
    1: '170 x 10',
    2: '501 x 5',
    3: '170 x 10 max 3',
    4: '501 x 5 max 7',
  };

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
                  MenuItem(
                    gameno: 1,
                    view: const ViewXXXCheckout(gameno: 1),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 170, 'max': -1, 'end': 10},
                  ),
                  MenuItem(
                    gameno: 2,
                    view: const ViewXXXCheckout(gameno: 2),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 501, 'max': -1, 'end': 5},
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MenuItem(
                    gameno: 3,
                    view: const ViewXXXCheckout(gameno: 3),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 170, 'max': 3, 'end': 10},
                  ),
                  MenuItem(
                    gameno: 4,
                    view: const ViewXXXCheckout(gameno: 4),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 501, 'max': 7, 'end': 5},
                  ),
                ],
              ),
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
    required this.gameno,
    required this.view,
    required this.controller,
    required this.params,
  });

  final int gameno;
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
            controller.init(gameno, params);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => view),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(width: 3.0, color: Colors.white),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Menu.games[gameno],
                style: const TextStyle(
                    fontSize: 50, color: Color.fromARGB(255, 215, 198, 132)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
