import 'package:get_storage/get_storage.dart';
import 'dart:developer' as developer;

/// Service class that wraps GetStorage operations with proper error handling
/// Falls back gracefully when storage operations fail
class StorageService {
  final GetStorage? _storage;
  final String _containerName;

  StorageService(this._containerName, {GetStorage? injectedStorage})
      : _storage = injectedStorage;

  /// Get the storage instance, creating it if needed
  GetStorage? get _storageInstance {
    try {
      return _storage ?? GetStorage(_containerName);
    } catch (e) {
      developer.log(
        'Failed to initialize storage for container: $_containerName',
        error: e,
        name: 'StorageService',
      );
      return null;
    }
  }

  /// Read a value from storage with error handling
  /// Returns the default value if storage fails or key doesn't exist
  T? read<T>(String key, {T? defaultValue}) {
    try {
      final storage = _storageInstance;
      if (storage == null) return defaultValue;
      
      return storage.read(key) ?? defaultValue;
    } catch (e) {
      developer.log(
        'Failed to read key "$key" from storage container "$_containerName"',
        error: e,
        name: 'StorageService',
      );
      return defaultValue;
    }
  }

  /// Write a value to storage with error handling
  /// Logs error and continues if storage fails
  bool write<T>(String key, T value) {
    try {
      final storage = _storageInstance;
      if (storage == null) return false;
      
      storage.write(key, value);
      return true;
    } catch (e) {
      developer.log(
        'Failed to write key "$key" to storage container "$_containerName"',
        error: e,
        name: 'StorageService',
      );
      return false;
    }
  }

  /// Check if storage is available
  bool get isAvailable {
    return _storageInstance != null;
  }
}
