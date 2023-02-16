import 'package:dart/view/view_170.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    Image image =
        Image.asset('assets/images/logo.png', width: 360, fit: BoxFit.fitWidth);
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
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const View170()),
                );
              },
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 3.0, color: Colors.white),
                  minimumSize: const Size(400, 50)),
              child: const Text(
                '170',
                style: TextStyle(
                    fontSize: 25, color: Color.fromARGB(255, 215, 198, 132)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
