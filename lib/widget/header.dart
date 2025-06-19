import 'package:dart/styles.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.gameName,
  });

  final String gameName;

  @override
  Widget build(BuildContext context) {
    Image image = Image.asset('assets/images/logo.png');
    return Row(
      children: [
        Expanded(
          flex: 20,
          child: image,
        ),
        Expanded(
          flex: 75,
          child: Text(
            gameName,
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 215, 198, 132),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: headerButtonStyle,
            child: const Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 215, 198, 132),
            ),
          ),
        ),
      ],
    );
  }
}
