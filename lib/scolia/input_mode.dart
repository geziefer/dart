/// Global input mode: the app is driven either by the on-screen numpad
/// (default) or by Scolia board detections. Persisted locally so the choice
/// survives restarts.
library;

import 'package:flutter/foundation.dart';
import 'package:dart/services/storage_service.dart';

enum InputMode { numpad, scolia }

class InputModeHolder extends ChangeNotifier {
  static const String containerName = 'scolia_settings';
  static const String _key = 'inputMode';

  final StorageService _storage;
  InputMode _mode;

  InputModeHolder({StorageService? storage})
      : _storage = storage ?? StorageService(containerName),
        _mode = InputMode.numpad {
    final saved = _storage.read<String>(_key, defaultValue: 'numpad');
    _mode = saved == 'scolia' ? InputMode.scolia : InputMode.numpad;
  }

  InputMode get mode => _mode;
  bool get isScolia => _mode == InputMode.scolia;

  void set(InputMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _storage.write<String>(_key, mode == InputMode.scolia ? 'scolia' : 'numpad');
    notifyListeners();
  }

  void toggle() =>
      set(_mode == InputMode.numpad ? InputMode.scolia : InputMode.numpad);
}
