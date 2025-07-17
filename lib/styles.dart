import 'package:flutter/material.dart';

final headerButtonStyle = OutlinedButton.styleFrom(
    side: const BorderSide(width: 3.0, color: Colors.white),
    minimumSize: const Size(40, 70),
    shape: const CircleBorder());

const menuButtonTextStyle = TextStyle(
  fontSize: 42,
  color: Color.fromARGB(255, 215, 198, 132),
);

final menuButtonStyle = OutlinedButton.styleFrom(
  side: const BorderSide(width: 1.0, color: Colors.white),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
);

final okButtonStyle = TextButton.styleFrom(
  backgroundColor: Colors.black,
  minimumSize: const Size(150, 80),
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2))),
);

const okButtonTextStyle = TextStyle(
  fontSize: 50,
  color: Colors.white,
);

final finishButtonStyle = TextButton.styleFrom(
  backgroundColor: Colors.black,
  shape: const BeveledRectangleBorder(),
);

const finishButtonTextStyle = TextStyle(
  fontSize: 50,
  color: Colors.white,
);

const statsTextStyle = TextStyle(
  fontSize: 50,
  color: Colors.white,
);

const statsNumberTextStyle = TextStyle(
  fontSize: 50,
  color: Color.fromARGB(255, 215, 198, 132),
);

const statsSummaryTextStyle = TextStyle(
  fontSize: 40,
  color: Colors.white,
);

const endSummaryHeaderTextStyle = TextStyle(
  fontSize: 50,
  color: Colors.black,
);

const endSummaryTextStyle = TextStyle(
  fontSize: 32,
  color: Colors.black,
);

const endSummaryEmphasizedTextStyle = TextStyle(
  fontSize: 35,
  color: Colors.red,
);

const checkNumberStyle = TextStyle(
  fontSize: 50,
  color: Color.fromARGB(255, 215, 198, 132),
);

const numpadInputTextStyle = TextStyle(
  fontSize: 70,
  color: Colors.white,
);

const numpadScoreButtonLargeTextStyle = TextStyle(
  fontSize: 50,
  color: Colors.white,
);

const numpadScoreButtonSmallTextStyle = TextStyle(
  fontSize: 35,
  color: Colors.white,
);

final numpadTextStyle = TextButton.styleFrom(
  backgroundColor: Colors.white24,
  shape: const BeveledRectangleBorder(),
);

final numpadDisabledTextStyle = TextButton.styleFrom(
  backgroundColor: Colors.grey.withValues(alpha: 0.3),
  shape: const BeveledRectangleBorder(),
);

const numpadScoreButtonLargeDisabledTextStyle = TextStyle(
  fontSize: 50,
  color: Colors.grey,
);

const numpadScoreButtonSmallDisabledTextStyle = TextStyle(
  fontSize: 32,
  color: Colors.grey,
);

const scoreLabelTextStyle = TextStyle(
  fontSize: 68,
  color: Color.fromARGB(255, 215, 198, 132),
);

const boardTextStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 30,
);
