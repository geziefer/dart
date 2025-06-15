import 'package:flutter/material.dart';

const menuButtonTextStyle = TextStyle(
  fontSize: 42,
  color: Color.fromARGB(255, 215, 198, 132),
);

final menuButtonStyle = OutlinedButton.styleFrom(
  side: const BorderSide(width: 1.0, color: Colors.white),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
);
