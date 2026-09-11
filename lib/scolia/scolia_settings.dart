/// Local-only storage for Scolia credentials (board serial number + access
/// token) and connection preferences.
///
/// Credentials are entered by the user at runtime and persisted **only** on the
/// device via the app's local key-value store (get_storage). They are NEVER
/// committed to source control — this repository is public.
library;

import 'package:dart/services/storage_service.dart';

class ScoliaSettings {
  static const String containerName = 'scolia_settings';
  static const String _keySerial = 'serialNumber';
  static const String _keyToken = 'accessToken';
  static const String _keySimulator = 'simulatorEnabled';

  final StorageService _storage;

  ScoliaSettings({StorageService? storage})
      : _storage = storage ?? StorageService(containerName);

  String get serialNumber =>
      _storage.read<String>(_keySerial, defaultValue: '') ?? '';

  String get accessToken =>
      _storage.read<String>(_keyToken, defaultValue: '') ?? '';

  /// When true, use the on-screen dartboard simulator instead of a real board.
  /// Defaults to true so the feature is usable without hardware.
  bool get simulatorEnabled =>
      _storage.read<bool>(_keySimulator, defaultValue: true) ?? true;

  set simulatorEnabled(bool value) =>
      _storage.write<bool>(_keySimulator, value);

  /// True once both credentials are present.
  bool get isConfigured =>
      serialNumber.isNotEmpty && accessToken.isNotEmpty;

  void save({required String serialNumber, required String accessToken}) {
    _storage.write<String>(_keySerial, serialNumber.trim());
    _storage.write<String>(_keyToken, accessToken.trim());
  }

  void clear() {
    _storage.write<String>(_keySerial, '');
    _storage.write<String>(_keyToken, '');
  }
}
