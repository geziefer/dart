import 'package:dart/controller/controller_170.dart';
import 'package:dart/view/view_170.dart';
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
                children: const [
                  MenuItem(
                    label: '170 x 10',
                    view: View170(),
                  ),
                  MenuItem(
                    label: '170 x 10 max 3',
                    view: View170(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  MenuItem(
                    label: '501 x 5',
                    view: View170(),
                  ),
                  MenuItem(
                    label: '501 x 5 max 7',
                    view: View170(),
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
  });

  final String label;
  final Widget view;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(5),
        child: OutlinedButton(
          onPressed: () {
            Controller170().init();
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
