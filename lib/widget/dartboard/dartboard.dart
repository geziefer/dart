import 'package:dart/widget/dartboard/arcsection.dart';
import 'package:dart/widget/dartboard/fullcircle.dart';
import 'package:flutter/material.dart';

class Dartboard extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final String appBarTitle;

  const Dartboard({super.key, 
    required this.title,
    required this.backgroundColor,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: Center(
        child: FullCircle(
          radius: 250,
          arcSections: [
            ArcSection(startPercent: 0.2),
            ArcSection(startPercent: 0.4),
            ArcSection(startPercent: 0.6),
            ArcSection(startPercent: 0.8),
          ],
        ),
      ),
      backgroundColor: backgroundColor,
    );
  }
}
