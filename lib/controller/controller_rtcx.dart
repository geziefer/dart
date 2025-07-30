import 'package:dart/controller/controller_base.dart';
import 'package:dart/interfaces/menuitem_controller.dart';
import 'package:dart/interfaces/numpad_controller.dart';
import 'package:dart/widget/checkout.dart';
import 'package:dart/widget/menu.dart';
import 'package:dart/widget/summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dart/services/storage_service.dart';
import 'package:provider/provider.dart';

class ControllerRTCX extends ControllerBase
    implements MenuitemController, NumpadController {
  StorageService? _storageService;
  final GetStorage? _injectedStorage;

  // Constructor with optional dependency injection for testing
  ControllerRTCX({GetStorage? storage}) : _injectedStorage = storage;

  // Factory for production use (maintains backward compatibility)
  factory ControllerRTCX.create() {
    return ControllerRTCX();
  }

  // Factory for testing with injected storage
  factory ControllerRTCX.forTesting(GetStorage storage) {
    return ControllerRTCX(storage: storage);
  }

  MenuItem? item; // item which created the controller
  int max = -1; // limit of rounds per leg (-1 = unlimited)

  List<int> throws = <int>[]; // list of checked doubles per round (index - 1)
  int currentNumber = 1; // current number to throw at
  int round = 1; // round number in game
  int dart = 0; // darts played in game
  bool finished = false; // flag if round the clock was finished

  @override
  void init(MenuItem item) {
    this.item = item;
    _storageService = StorageService(item.id, injectedStorage: _injectedStorage);
    max = item.params['max'];

    throws = <int>[];
    currentNumber = 1;
    round = 1;
    dart = 0;
    finished = false;
  }

  @override
  void initFromProvider(BuildContext context, MenuItem item) {
    Provider.of<ControllerRTCX>(context, listen: false).init(item);
  }

  @override
  void pressNumpadButton(BuildContext context, int value) {
    // undo button pressed
    if (value == -2) {
      if (throws.isNotEmpty) {
        round--;
        dart -= 3;
        int lastThrow = throws.removeLast();
        currentNumber -= lastThrow;
      }
      // all other buttons pressed
    } else {
      // ignore numbers greater left checks
      if (currentNumber + value <= 21) {
        // return button pressed
        if (value == -1) {
          value = 0;
        }
        dart += 3;
        throws.add(value);
        currentNumber += value;

        notifyListeners();

        // check for last number reached or limit of rounds
        if (currentNumber > 20 || (max != -1 && round == max)) {
          // remaining is dfferent here, 20 means finished game,
          // so set to current number if not
          int remaining = (currentNumber < 21) ? currentNumber : 0;
          finished = currentNumber > 20 ? true : false;
          if (finished) {
            _showCheckoutDialog(context, remaining);
          } else {
            _showSummaryDialog(context);
          }
        } else {
          round++;
        }
      }
    }
    notifyListeners();
  }

  // Show checkout dialog using a callback-based approach
  void _showCheckoutDialog(BuildContext context, int remaining) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2))),
          // no remaining score here, so set last one
          child: Checkout(
            remaining: remaining,
            controller: this,
          ),
        );
      },
    ).then((_) {
      // Use post-frame callback to avoid context across async gaps
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSummaryDialog(context);
      });
    });
  }

  // Update game statistics and show summary dialog
  void _showSummaryDialog(BuildContext context) {
    // Save stats to device, use gameno as key
    _updateGameStats();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String checkSymbol = finished ? "✅" : "❌";
        return SummaryDialog(
          lines: [
            SummaryLine('RTC geschafft', '', checkSymbol: checkSymbol),
            SummaryLine('Anzahl Darts', '$dart'),
            SummaryLine('Darts/Checkout', getCurrentStats()['avgChecks'],
                emphasized: true),
          ],
        );
      },
    );
  }

  // Update game statistics
  void _updateGameStats() {
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int numberFinishes = _storageService!.read<int>('numberFinishes', defaultValue: 0)!;
    int recordDarts = _storageService!.read<int>('recordDarts', defaultValue: 0)!;
    double longtermChecks = _storageService!.read<double>('longtermChecks', defaultValue: 0.0)!;
    double avgChecks = _getAvgChecks();

    _storageService!.write('numberGames', numberGames + 1);
    if (finished) {
      _storageService!.write('numberFinishes', numberFinishes + 1);
    }
    if (recordDarts == 0 || dart < recordDarts) {
      _storageService!.write('recordDarts', dart);
    }
    _storageService!.write('longtermChecks',
        (((longtermChecks * numberGames) + avgChecks) / (numberGames + 1)));
  }

  int getCurrentNumber() {
    return currentNumber;
  }

  double _getAvgChecks() {
    return currentNumber == 1 ? 0 : (dart / (currentNumber - 1));
  }

  @override
  String getInput() {
    // not used here
    return "";
  }

  @override
  void correctDarts(int value) {
    dart -= value;

    notifyListeners();
  }

  @override
  bool isButtonDisabled(int value) {
    return false; // no buttons disabled in rtcx
  }

  Map getCurrentStats() {
    return {
      'throw': round,
      'darts': dart,
      'avgChecks': _getAvgChecks().toStringAsFixed(1),
    };
  }

  String getStats() {
    // read stats from device, use gameno as key
    int numberGames = _storageService!.read<int>('numberGames', defaultValue: 0)!;
    int numberFinishes = _storageService!.read<int>('numberFinishes', defaultValue: 0)!;
    int recordDarts = _storageService!.read<int>('recordDarts', defaultValue: 0)!;
    double longtermChecks = _storageService!.read<double>('longtermChecks', defaultValue: 0.0)!;
    return '#S: $numberGames  #G: $numberFinishes  ♛D: $recordDarts  ØC: ${longtermChecks.toStringAsFixed(1)}';
  }
}
