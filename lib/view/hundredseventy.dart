import 'dart:ui';

import 'package:flutter/material.dart';

class HundredSeventy extends StatelessWidget {
  const HundredSeventy({super.key});

  @override
  Widget build(BuildContext context) {
    Image image = Image.asset('assets/images/logo.png');
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      body: Column(
        children: [
          Expanded(
            flex: 1,

            // ########## Top row with logo, game title and back button
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: image,
                ),
                const Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      '170',
                      style: TextStyle(
                        fontSize: 42,
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
                        side: const BorderSide(
                          width: 3.0,
                          color: Colors.white,
                        ),
                        minimumSize: const Size(40, 50)),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color.fromARGB(255, 215, 198, 132),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ########## Main part with game results and num pad
          Expanded(
            flex: 8,
            child: Column(
              children: [
                const Divider(
                  color: Colors.white,
                  thickness: 3,
                ),
                Expanded(
                  child: Row(
                    children: [
                      // ########## Left column with game results
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            const SizedBox(width: 50),
                            // ########## Throw number
                            Column(
                              children: const [
                                Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  '\n1\n2\n3\n4',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontFeatures: <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                              color: Colors.white,
                              thickness: 1,
                            ),
                            const SizedBox(width: 10),
                            // ########## Thrown score in round
                            Column(
                              children: const [
                                Text(
                                  'W',
                                  style: TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  '\n26\n100\n12\n32',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontFeatures: <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                              color: Colors.white,
                              thickness: 1,
                            ),
                            const SizedBox(width: 10),
                            // ########## Score left
                            Column(
                              children: const [
                                Text(
                                  'R',
                                  style: TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  '170\n144\n44\n32\n0',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontFeatures: <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(
                              color: Colors.white,
                              thickness: 1,
                            ),
                            const SizedBox(width: 10),
                            // ########## Darts thrown
                            Column(
                              children: const [
                                Text(
                                  'D',
                                  style: TextStyle(
                                    fontSize: 50,
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                ),
                                Text(
                                  '\n3\n6\n9\n11',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontFeatures: <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: Color.fromARGB(255, 215, 198, 132),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.white,
                        thickness: 3,
                      ),

                      // ########## Right column with num pad
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              // ########## 1st row 7, 8, 9
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '7',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '8',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '9',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              // ########## 2nd row 4, 5, 6
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '4',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '5',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '6',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              // ########## 3rd row 1, 2, 3
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '1',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '2',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '3',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              // ########## 4th row back, 0, enter
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '↶',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(5),
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                        ),
                                        child: const Text(
                                          '↵',
                                          style: TextStyle(
                                            fontSize: 50,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white,
                  thickness: 3,
                ),
              ],
            ),
          ),

          // ########## Bottom row with stats
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Runde: 10   Ø Punkte: 70   Ø Darts: 7',
                style: TextStyle(
                  fontSize: 36,
                  color: Color.fromARGB(255, 215, 198, 132),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
