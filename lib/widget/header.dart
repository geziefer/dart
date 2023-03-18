import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.gameno,
  });

  final int gameno;

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
            Menu.games[gameno]!.replaceAll("\n", " "),
            style: const TextStyle(
              fontSize: 60,
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
            style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 3.0, color: Colors.white),
                minimumSize: const Size(40, 70)),
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
