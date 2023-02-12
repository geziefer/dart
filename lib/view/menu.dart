import 'package:dart/view/hundredseventy.dart';
import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HundredSeventy()),
                );
              },
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    width: 3.0,
                    color: Colors.white,
                  ),
                  minimumSize: const Size(400, 50)),
              child: const Text(
                '170',
                style: TextStyle(
                  fontSize: 25,
                  color: Color.fromARGB(255, 215, 198, 132),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
