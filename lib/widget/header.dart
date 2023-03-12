import 'package:dart/widget/menu.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.gameno,
    required this.label,
  });

  final int gameno;
  final String label;

  @override
  Widget build(BuildContext context) {
    Image image = Image.asset('assets/images/logo.png');
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: image,
        ),
        Expanded(
          flex: 7,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Menu.games[gameno],
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 215, 198, 132),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
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
