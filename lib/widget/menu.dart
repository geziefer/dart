import 'package:dart/controller/controller_xxxcheckout.dart';
import 'package:dart/view/view_xxxcheckout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Menu extends StatelessWidget {
  const Menu({
    super.key,
  });

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
                    label: '170 x 10',
                    view: const ViewXXXCheckout(title: '170 x 10'),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 170, 'max': -1},
                  ),
                  MenuItem(
                    label: '501 x 5',
                    view: const ViewXXXCheckout(title: '501 x 5'),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 501, 'max': -1},
                  ),
                  MenuItem(
                    label: '999 x 5',
                    view: const ViewXXXCheckout(title: '999 x 5'),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 999, 'max': -1},
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
                    label: '170 x 10 max 3',
                    view: const ViewXXXCheckout(title: '170 x 10 max 3'),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 170, 'max': 3},
                  ),
                  MenuItem(
                    label: '501 x 5 max 7',
                    view: const ViewXXXCheckout(title: '501 x 5 max 7'),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 501, 'max': 7},
                  ),
                  MenuItem(
                    label: '999 x 5 max 14',
                    view: const ViewXXXCheckout(title: '999 x 5 max 14'),
                    controller: ControllerXXXCheckout(),
                    params: const {'xxx': 999, 'max': 14},
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
    required this.label,
    required this.view,
    required this.controller,
    required this.params,
  });

  final String label;
  final Widget view;
  final Initializable controller;
  final Map params;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: OutlinedButton(
          onPressed: () {
            controller.init(params);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => view),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(width: 3.0, color: Colors.white),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 50, color: Color.fromARGB(255, 215, 198, 132)),
          ),
        ),
      ),
    );
  }
}

/// Interface for Controller to initialize
abstract class Initializable {
  void init(Map params);
}
