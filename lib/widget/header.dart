import 'package:dart/styles.dart';
import 'package:dart/utils/responsive.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.gameName,
    this.onBack,
  });

  final String gameName;

  /// Called when the back arrow is tapped. Defaults to a plain
  /// `Navigator.pop` when not provided.
  final VoidCallback? onBack;

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
              fontSize: 50 * ResponsiveUtils.getHeaderTextScale(context),
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
              if (onBack != null) {
                onBack!();
              } else {
                Navigator.pop(context);
              }
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
