import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    Image image =
        Image.asset('assets/images/logo.png', width: 360, fit: BoxFit.fitWidth);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'Damit Alex Richtig Trainiert',
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 17, 17, 17),
        body: Center(
          child: Column(
            children: [
              image,
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      width: 3.0,
                      color: Colors.white,
                    ),
                    minimumSize: const Size(400, 50)),
                child: const Text(
                  '170 to 0',
                  style: TextStyle(
                    fontSize: 25,
                    color: Color.fromARGB(255, 215, 198, 132),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
