import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.label,
  }) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    Image image = Image.asset('assets/images/logo.png');
    return Row(
      children: [
        const SizedBox(height: 20),
        Expanded(
          flex: 2,
          child: image,
        ),
        Expanded(
          flex: 7,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 215, 198, 132),
              ),
            ),
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
                minimumSize: const Size(40, 50)),
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
