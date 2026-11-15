import 'package:dart/controller/controller_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wraps a game view that was started by a dart thrown in the menu. While the
/// thrown dart is still on the board it shows a cancelable "remove darts"
/// popup; the state lives in [ControllerMenu]. Tapping outside the card or
/// "Abbrechen" dismisses it, so the game (and its back button) stays usable
/// even if the board never reports a takeout.
class TakeoutGate extends StatelessWidget {
  const TakeoutGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<ControllerMenu?>();
    if (menu == null || !menu.awaitingTakeout) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            onTap: menu.cancelTakeoutWait,
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // taps on the card itself don't dismiss
                  child: Material(
                    color: const Color.fromARGB(255, 34, 34, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          const Text(
                            'Bitte Darts entfernen',
                            style: TextStyle(color: Colors.white, fontSize: 28),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: menu.cancelTakeoutWait,
                            child: const Text(
                              'Abbrechen',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 215, 198, 132),
                                  fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
