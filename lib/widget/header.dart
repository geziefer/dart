import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
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
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 50),
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 215, 198, 132),
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
            style: headerButtonStyle(context),
            child: Icon(
              Icons.arrow_back,
              color: const Color.fromARGB(255, 215, 198, 132),
              size: ResponsiveUtils.getResponsiveFontSize(
                  context, 40), // Make it larger and responsive
            ),
          ),
        ),
      ],
    );
  }
}
