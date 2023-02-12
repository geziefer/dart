import 'package:flutter/material.dart';

class HundredSeventy extends StatelessWidget {
  const HundredSeventy({super.key});

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
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    width: 3.0,
                    color: Colors.white,
                  ),
                  minimumSize: const Size(400, 50)),
              child: const Icon(
                Icons.arrow_back,
                color: Color.fromARGB(255, 215, 198, 132),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
